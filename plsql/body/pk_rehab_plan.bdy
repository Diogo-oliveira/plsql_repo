/*-- Last Change Revision: $Rev: 1860792 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2018-08-28 17:03:48 +0100 (ter, 28 ago 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_plan IS

    -- Private type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Private constant declarations
    --<ConstantName> CONSTANT <Datatype> := <Value>;

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    PROCEDURE update_objective_history
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_epis_plan   IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_dt_current_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) IS
    
        l_id_episode      episode.id_episode%TYPE := NULL;
        l_tbl_id_prof_cat table_number;
    
        l_count_active_records      NUMBER := 0;
        l_tbl_rehab_epis_plan_area  table_number;
        l_id_rehab_plan_area        rehab_epis_plan_area.id_rehab_plan_area%TYPE;
        l_current_situation         rehab_epis_plan_area.current_situation%TYPE;
        l_goals                     rehab_epis_plan_area.goals%TYPE;
        l_methodology               rehab_epis_plan_area.methodology%TYPE;
        l_time                      rehab_epis_plan_area.time%TYPE;
        l_flg_time_unit             rehab_epis_plan_area.flg_time_unit%TYPE;
        l_id_prof_create            rehab_epis_plan_area.id_prof_create%TYPE;
        l_id_rehab_epis_plan_aux    rehab_epis_plan_area.id_rehab_epis_plan%TYPE;
        id_rehab_epis_plan_area_out rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE := NULL;
        rows_out                    table_varchar;
    
        e_controlled_error EXCEPTION;
    
        FUNCTION get_plan_area_params
        (
            i_id_rehab_epis_plan_area IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
            i_id_rehab_plan_area      OUT rehab_epis_plan_area.id_rehab_plan_area%TYPE,
            i_current_situation       OUT rehab_epis_plan_area.current_situation%TYPE,
            i_goals                   OUT rehab_epis_plan_area.goals%TYPE,
            i_methodology             OUT rehab_epis_plan_area.methodology%TYPE,
            i_time                    OUT rehab_epis_plan_area.time%TYPE,
            i_flg_time_unit           OUT rehab_epis_plan_area.flg_time_unit%TYPE,
            i_id_prof_create          OUT rehab_epis_plan_area.id_prof_create%TYPE,
            i_id_rehab_epis_plan      OUT rehab_epis_plan_area.id_rehab_epis_plan%TYPE
        ) RETURN BOOLEAN IS
        BEGIN
        
            SELECT r.id_rehab_plan_area,
                   r.current_situation,
                   r.goals,
                   r.methodology,
                   r.time,
                   r.flg_time_unit,
                   r.id_prof_create,
                   r.id_rehab_epis_plan
              INTO i_id_rehab_plan_area,
                   i_current_situation,
                   i_goals,
                   i_methodology,
                   i_time,
                   i_flg_time_unit,
                   i_id_prof_create,
                   i_id_rehab_epis_plan
              FROM rehab_epis_plan_area r
             WHERE r.id_rehab_epis_plan_area = i_id_rehab_epis_plan_area
               AND r.flg_status = 'Y';
        
            RETURN TRUE;
        END get_plan_area_params;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count_active_records
          FROM rehab_epis_plan_area a
         WHERE a.id_rehab_epis_plan = i_id_rehab_epis_plan
           AND a.flg_status = pk_alert_constant.g_yes;
    
        IF l_count_active_records > 0
        THEN
            SELECT a.id_rehab_epis_plan_area
              BULK COLLECT
              INTO l_tbl_rehab_epis_plan_area
              FROM rehab_epis_plan_area a
             WHERE a.id_rehab_epis_plan = i_id_rehab_epis_plan
               AND a.flg_status = pk_alert_constant.g_yes;
        
            FOR i IN l_tbl_rehab_epis_plan_area.first .. l_tbl_rehab_epis_plan_area.last
            LOOP
            
                IF NOT get_plan_area_params(i_id_rehab_epis_plan_area => l_tbl_rehab_epis_plan_area(i),
                                            i_id_rehab_plan_area      => l_id_rehab_plan_area,
                                            i_current_situation       => l_current_situation,
                                            i_goals                   => l_goals,
                                            i_methodology             => l_methodology,
                                            i_time                    => l_time,
                                            i_flg_time_unit           => l_flg_time_unit,
                                            i_id_prof_create          => l_id_prof_create,
                                            i_id_rehab_epis_plan      => l_id_rehab_epis_plan_aux)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
                UPDATE rehab_epis_plan_area r
                   SET r.flg_status = 'N'
                 WHERE r.id_rehab_epis_plan_area = l_tbl_rehab_epis_plan_area(i);
            
                IF NOT pk_rehab_epis_plan_area.ins(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   id_rehab_epis_plan_in       => l_id_rehab_epis_plan_aux,
                                                   id_rehab_plan_area_in       => l_id_rehab_plan_area,
                                                   current_situation_in        => l_current_situation,
                                                   goals_in                    => l_goals,
                                                   methodology_in              => l_methodology,
                                                   time_in                     => l_time,
                                                   flg_time_unit_in            => l_flg_time_unit,
                                                   id_professional_in          => l_id_prof_create,
                                                   dt_rehab_epis_plan_area_in  => i_dt_current_timestamp,
                                                   id_rehab_epis_plan_area_out => id_rehab_epis_plan_area_out,
                                                   o_error                     => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END LOOP;
        END IF;
    
    END update_objective_history;

    PROCEDURE update_notes_history
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_epis_plan   IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_dt_current_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) IS
    
        l_count_active_records NUMBER := 0;
    
        l_tbl_rehab_epis_plan_notes table_number;
        l_flg_type                  rehab_epis_plan_notes.flg_type%TYPE;
        l_notes                     rehab_epis_plan_notes.notes%TYPE;
        l_id_prof_create            rehab_epis_plan_notes.id_prof_create%TYPE;
        l_id_rehab_epis_plan_notes  rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE;
    
        e_controlled_error EXCEPTION;
    
        FUNCTION get_plan_notes_params
        (
            i_id_rehab_epis_plan_notes IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
            o_flg_type                 OUT rehab_epis_plan_notes.flg_type%TYPE,
            o_notes                    OUT rehab_epis_plan_notes.notes%TYPE,
            o_id_prof_create           OUT rehab_epis_plan_notes.id_prof_create%TYPE
        ) RETURN BOOLEAN IS
        BEGIN
        
            SELECT r.flg_type, r.notes, r.id_prof_create
              INTO o_flg_type, o_notes, o_id_prof_create
              FROM rehab_epis_plan_notes r
             WHERE r.id_rehab_epis_plan_notes = i_id_rehab_epis_plan_notes
               AND r.flg_status = 'Y';
        
            RETURN TRUE;
        END get_plan_notes_params;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count_active_records
          FROM rehab_epis_plan_notes r
         WHERE r.id_rehab_epis_plan = i_id_rehab_epis_plan
           AND r.flg_status = pk_alert_constant.g_yes;
    
        IF l_count_active_records > 0
        THEN
            SELECT n.id_rehab_epis_plan_notes
              BULK COLLECT
              INTO l_tbl_rehab_epis_plan_notes
              FROM rehab_epis_plan_notes n
             WHERE n.id_rehab_epis_plan = i_id_rehab_epis_plan
               AND n.flg_status = pk_alert_constant.g_yes;
        
            FOR i IN l_tbl_rehab_epis_plan_notes.first .. l_tbl_rehab_epis_plan_notes.last
            LOOP
            
                IF NOT get_plan_notes_params(i_id_rehab_epis_plan_notes => l_tbl_rehab_epis_plan_notes(i),
                                             o_flg_type                 => l_flg_type,
                                             o_notes                    => l_notes,
                                             o_id_prof_create           => l_id_prof_create)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
                UPDATE rehab_epis_plan_notes n
                   SET n.flg_status = 'N'
                 WHERE n.id_rehab_epis_plan_notes = l_tbl_rehab_epis_plan_notes(i);
            
                IF NOT pk_rehab_epis_plan_notes.ins(i_lang                       => i_lang,
                                                    i_prof                       => i_prof,
                                                    id_rehab_epis_plan_in        => i_id_rehab_epis_plan,
                                                    flg_type_in                  => l_flg_type,
                                                    notes_in                     => l_notes,
                                                    id_professional_in           => l_id_prof_create,
                                                    dt_rehab_epis_plan_notes_in  => i_dt_current_timestamp,
                                                    id_rehab_epis_plan_notes_out => l_id_rehab_epis_plan_notes,
                                                    o_error                      => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END LOOP;
        END IF;
    
    END update_notes_history;

    PROCEDURE update_rehab_plan_history
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_epis_plan   IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_dt_current_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) IS
    
        l_id_episode      episode.id_episode%TYPE := NULL;
        l_tbl_id_prof_cat table_number;
    
        e_controlled_error EXCEPTION;
    BEGIN
        BEGIN
        
            SELECT rep.id_episode
              INTO l_id_episode
              FROM rehab_epis_plan rep
             WHERE rep.id_rehab_epis_plan = i_id_rehab_epis_plan;
        
            SELECT r.id_prof_cat
              BULK COLLECT
              INTO l_tbl_id_prof_cat
              FROM rehab_epis_plan_team r
             WHERE r.id_rehab_epis_plan = i_id_rehab_epis_plan
               AND r.flg_status = 'Y';
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_episode := NULL;
        END;
    
        IF l_id_episode IS NOT NULL
        THEN
            IF NOT pk_rehab_plan.set_general_info(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                  i_id_episode         => l_id_episode,
                                                  i_id_prof_cat        => l_tbl_id_prof_cat,
                                                  i_creat_date         => NULL,
                                                  i_current_timestamp  => i_dt_current_timestamp,
                                                  o_error              => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        END IF;
    
    END update_rehab_plan_history;

    /**
    * get_rehab_menu_plans
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:14:35
    */
    FUNCTION get_rehab_menu_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_rehab_menu_plans';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan_area_inst.get_rehab_menu_plans(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_subject    => i_subject,
                                                            i_from_state => i_from_state,
                                                            o_actions    => o_actions,
                                                            o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rehab_menu_plans;

    /**
    * get_prof_by_cat
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:18:44
    */
    FUNCTION get_prof_by_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_category IN category.id_category%TYPE DEFAULT NULL,
        o_curs        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_prof_by_cat';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan_team.get_prof_by_cat(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_category => i_id_category,
                                                  o_curs        => o_curs,
                                                  o_error       => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_by_cat;

    /**
    * get_team
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:22:18
    */
    FUNCTION get_team
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_team';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan_team.get_team(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                o_team               => o_team,
                                                o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_team;

    /**
    * get_general_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_general_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_general_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan.get_general_info(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_rehab_epis_plan => NULL,
                                                   i_id_episode         => i_id_episode,
                                                   o_info               => o_info,
                                                   o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_team.get_list_by_pat_ep(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode,
                                                          i_id_patient => NULL,
                                                          i_flg_status => 'O',
                                                          o_teams      => o_team,
                                                          o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_general_info;

    /**
    * set_plan_areas
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 11:18:28
    */
    FUNCTION set_plan_areas
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        i_current_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_plan_areas';
        e_controlled_error EXCEPTION;
        l_action_message               sys_message.desc_message%TYPE;
        l_error_message                sys_message.desc_message%TYPE;
        id_rehab_epis_plan_area_out    rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE := NULL;
        id_rehab_epis_plan_area_team_o rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE := NULL;
        id_rehab_epis_plan_notes_out   rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE := NULL;
        dt_current_timestamp           TIMESTAMP WITH LOCAL TIME ZONE;
        n_id_episode                   NUMBER;
    
    BEGIN
        dt_current_timestamp := i_current_timestamp;
        g_error              := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        --AREA
        update_objective_history(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_rehab_epis_plan   => i_id_rehab_epis_plan,
                                 i_dt_current_timestamp => dt_current_timestamp,
                                 o_error                => o_error);
        --NOTES
        update_notes_history(i_lang                 => i_lang,
                             i_prof                 => i_prof,
                             i_id_rehab_epis_plan   => i_id_rehab_epis_plan,
                             i_dt_current_timestamp => dt_current_timestamp,
                             o_error                => o_error);
        --
        FOR i IN 1 .. i_id_rehab_plan_area.count
        LOOP
            IF i_id_rehab_epis_plan_area(i) IS NULL
            THEN
                IF NOT pk_rehab_epis_plan_area.ins(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   id_rehab_epis_plan_in       => i_id_rehab_epis_plan,
                                                   id_rehab_plan_area_in       => i_id_rehab_plan_area(i),
                                                   current_situation_in        => i_current_situation(i),
                                                   goals_in                    => i_goals(i),
                                                   methodology_in              => i_methodology(i),
                                                   time_in                     => i_time(i),
                                                   flg_time_unit_in            => i_flg_time_unit(i),
                                                   id_professional_in          => i_prof.id,
                                                   dt_rehab_epis_plan_area_in  => dt_current_timestamp,
                                                   id_rehab_epis_plan_area_out => id_rehab_epis_plan_area_out,
                                                   o_error                     => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
                id_rehab_epis_plan_area_team_o := pk_rehab_epis_plan_area_team.next_key();
                IF i_id_prof_cat(i) IS NOT NULL
                THEN
                    FOR j IN 1 .. i_id_prof_cat(i).count
                    LOOP
                        IF NOT pk_rehab_epis_plan_area_team.ins(i_lang                         => i_lang,
                                                                i_prof                         => i_prof,
                                                                id_rehab_epis_plan_area_in     => id_rehab_epis_plan_area_out,
                                                                id_prof_cat_in                 => i_id_prof_cat(i) (j),
                                                                id_professional_in             => i_prof.id,
                                                                dt_rehab_epis_plan_team_in     => dt_current_timestamp,
                                                                id_rehab_epis_plan_area_team_i => id_rehab_epis_plan_area_team_o,
                                                                o_error                        => o_error)
                        THEN
                            RAISE e_controlled_error;
                        END IF;
                    END LOOP;
                END IF;
            
            ELSE
                IF NOT pk_rehab_epis_plan_area_team.update_plan_area(i_lang                    => i_lang,
                                                                     i_prof                    => i_prof,
                                                                     i_id_rehab_epis_plan_area => i_id_rehab_epis_plan_area(i),
                                                                     o_error                   => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
                IF NOT pk_rehab_epis_plan_area.upd(i_lang                     => i_lang,
                                                   i_prof                     => i_prof,
                                                   id_rehab_epis_plan_area_in => i_id_rehab_epis_plan_area(i),
                                                   current_situation_in       => i_current_situation(i),
                                                   goals_in                   => i_goals(i),
                                                   methodology_in             => i_methodology(i),
                                                   time_in                    => i_time(i),
                                                   flg_time_unit_in           => i_flg_time_unit(i),
                                                   id_professional_in         => i_prof.id,
                                                   dt_rehab_epis_plan_area_in => dt_current_timestamp,
                                                   o_error                    => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
                id_rehab_epis_plan_area_team_o := pk_rehab_epis_plan_area_team.next_key();
                IF i_id_prof_cat(i) IS NOT NULL
                THEN
                    FOR j IN 1 .. i_id_prof_cat(i).count
                    LOOP
                        IF NOT pk_rehab_epis_plan_area_team.ins(i_lang                         => i_lang,
                                                                i_prof                         => i_prof,
                                                                id_rehab_epis_plan_area_in     => i_id_rehab_epis_plan_area(i),
                                                                id_prof_cat_in                 => i_id_prof_cat(i) (j),
                                                                id_professional_in             => i_prof.id,
                                                                dt_rehab_epis_plan_team_in     => dt_current_timestamp,
                                                                id_rehab_epis_plan_area_team_i => id_rehab_epis_plan_area_team_o,
                                                                o_error                        => o_error)
                        THEN
                            RAISE e_controlled_error;
                        END IF;
                    END LOOP;
                END IF;
            
            END IF;
        
        END LOOP;
    
        FOR i IN 1 .. i_id_rehab_epis_plan_notes.count
        LOOP
            IF i_id_rehab_epis_plan_notes(i) IS NULL
            THEN
            
                IF NOT pk_rehab_epis_plan_notes.ins(i_lang                       => i_lang,
                                                    i_prof                       => i_prof,
                                                    id_rehab_epis_plan_in        => i_id_rehab_epis_plan,
                                                    flg_type_in                  => 'N',
                                                    notes_in                     => i_notes(i),
                                                    id_professional_in           => i_prof.id,
                                                    dt_rehab_epis_plan_notes_in  => dt_current_timestamp,
                                                    id_rehab_epis_plan_notes_out => id_rehab_epis_plan_notes_out,
                                                    o_error                      => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
            ELSE
                IF NOT pk_rehab_epis_plan_notes.upd(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    id_rehab_epis_plan_notes_in => i_id_rehab_epis_plan_notes(i),
                                                    flg_type_in                 => 'N',
                                                    notes_in                    => i_notes(i),
                                                    id_professional_in          => i_prof.id,
                                                    dt_rehab_epis_plan_notes_in => dt_current_timestamp,
                                                    o_error                     => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END IF;
        
        END LOOP;
    
        FOR i IN 1 .. i_id_rehab_epis_plan_sug.count
        LOOP
            IF i_id_rehab_epis_plan_sug(i) IS NULL
            THEN
            
                IF NOT pk_rehab_epis_plan_notes.ins(i_lang                       => i_lang,
                                                    i_prof                       => i_prof,
                                                    id_rehab_epis_plan_in        => i_id_rehab_epis_plan,
                                                    flg_type_in                  => 'S',
                                                    notes_in                     => i_suggestions(i),
                                                    id_professional_in           => i_prof.id,
                                                    dt_rehab_epis_plan_notes_in  => dt_current_timestamp,
                                                    id_rehab_epis_plan_notes_out => id_rehab_epis_plan_notes_out,
                                                    o_error                      => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            
            ELSE
                IF NOT pk_rehab_epis_plan_notes.upd(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    id_rehab_epis_plan_notes_in => i_id_rehab_epis_plan_sug(i),
                                                    flg_type_in                 => 'S',
                                                    notes_in                    => i_suggestions(i),
                                                    id_professional_in          => i_prof.id,
                                                    dt_rehab_epis_plan_notes_in => dt_current_timestamp,
                                                    o_error                     => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END IF;
        
        END LOOP;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_plan_areas;

    /**
    * set_general_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 15:06:12
    */
    FUNCTION set_general_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_prof_cat        IN table_number,
        i_creat_date         IN VARCHAR2,
        i_current_timestamp  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_general_info';
        e_controlled_error EXCEPTION;
        l_action_message          sys_message.desc_message%TYPE;
        l_error_message           sys_message.desc_message%TYPE;
        id_rehab_epis_plan_out    rehab_epis_plan.id_rehab_epis_plan%TYPE;
        id_rehab_epis_plan_team_o rehab_epis_plan_team.id_rehab_epis_plan_team%TYPE;
        dt_current_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        dt_current_timestamp := i_current_timestamp;
        g_error              := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF i_id_rehab_epis_plan IS NULL
        THEN
            IF NOT pk_rehab_epis_plan.ins(i_lang                 => i_lang,
                                          i_prof                 => i_prof,
                                          id_episode_in          => i_id_episode,
                                          flg_status_in          => 'O',
                                          id_professional_in     => i_prof.id,
                                          dt_rehab_epis_plan_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_creat_date,
                                                                                                  NULL),
                                          dt_last_update_in      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_creat_date,
                                                                                                  NULL),
                                          id_rehab_epis_plan_out => id_rehab_epis_plan_out,
                                          o_error                => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        
            id_rehab_epis_plan_team_o := pk_rehab_epis_plan_team.next_key();
            FOR i IN 1 .. i_id_prof_cat.count
            LOOP
                IF NOT pk_rehab_epis_plan_team.ins(i_lang                     => i_lang,
                                                   i_prof                     => i_prof,
                                                   dt_rehab_epis_plan_team_in => pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               i_creat_date,
                                                                                                               NULL),
                                                   id_prof_cat_in             => i_id_prof_cat(i),
                                                   id_professional_in         => i_prof.id,
                                                   id_rehab_epis_plan_in      => id_rehab_epis_plan_out,
                                                   id_rehab_epis_plan_team_in => id_rehab_epis_plan_team_o,
                                                   o_error                    => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END LOOP;
        ELSE
        
            IF NOT pk_rehab_epis_plan_team.update_plan_area(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                            o_error              => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        
            IF NOT pk_rehab_epis_plan.upd(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          id_rehab_epis_plan_in => i_id_rehab_epis_plan,
                                          id_episode_in         => i_id_episode,
                                          flg_status_in         => 'O',
                                          id_professional_in    => i_prof.id,
                                          dt_rehab_epis_plan_in => dt_current_timestamp,
                                          dt_last_update_in     => dt_current_timestamp,
                                          o_error               => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        
            id_rehab_epis_plan_team_o := pk_rehab_epis_plan_team.next_key();
            FOR i IN 1 .. i_id_prof_cat.count
            LOOP
                IF NOT pk_rehab_epis_plan_team.ins(i_lang                     => i_lang,
                                                   i_prof                     => i_prof,
                                                   dt_rehab_epis_plan_team_in => dt_current_timestamp,
                                                   id_prof_cat_in             => i_id_prof_cat(i),
                                                   id_professional_in         => i_prof.id,
                                                   id_rehab_epis_plan_in      => i_id_rehab_epis_plan,
                                                   id_rehab_epis_plan_team_in => id_rehab_epis_plan_team_o,
                                                   o_error                    => o_error)
                THEN
                    RAISE e_controlled_error;
                END IF;
            END LOOP;
        
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_general_info;

    /**
    * get_all_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 17:23:09
    */
    FUNCTION get_all_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan_area.get_all_plan(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                    o_info               => o_info,
                                                    o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
        IF NOT pk_rehab_epis_plan_notes.get_all_plan(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                     i_notes_type         => 'N',
                                                     o_notes              => o_notes,
                                                     o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_notes.get_all_plan(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                     i_notes_type         => 'S',
                                                     o_notes              => o_suggest,
                                                     o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_area_team.get_all_profs(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                          o_obj_profs          => o_obj_profs,
                                                          o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_plan;

    /**
    * get_gen_prof_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_gen_prof_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_gen_prof_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan.get_general_info(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                   i_id_episode         => NULL,
                                                   o_info               => o_info,
                                                   o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_team.get_team(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                o_team               => o_team,
                                                o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_gen_prof_info;

    /**
    * get_list_by_pat_ep
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_list_by_pat_ep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_teams      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_list_by_pat_ep';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan.get_list_by_pat_ep(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id_episode,
                                                     i_id_patient => i_id_patient,
                                                     o_info       => o_info,
                                                     o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_team.get_list_by_pat_ep(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode,
                                                          i_id_patient => i_id_patient,
                                                          o_teams      => o_teams,
                                                          o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_list_by_pat_ep;

    /**
    * get_domains
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-12-2010 12:12:32
    */
    FUNCTION get_domains
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_domain      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_domains';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_sysdomain.get_values_domain(i_code_domain, i_lang, o_domain, o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_domains;

    /**
    * cancel_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan.cancel_plan(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                              dt_last_update_in    => current_timestamp,
                                              o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_plan;

    /**
    * cancel_area
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_area';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
        dt_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        dt_current_timestamp := current_timestamp;
    
        IF NOT pk_rehab_epis_plan_area.cancel_area(i_lang                     => i_lang,
                                                   i_prof                     => i_prof,
                                                   i_id_rehab_epis_plan       => i_id_rehab_epis_plan,
                                                   i_id_rehab_plan_area       => i_id_rehab_plan_area,
                                                   dt_rehab_epis_plan_area_in => dt_current_timestamp,
                                                   o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        update_objective_history(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_rehab_epis_plan   => i_id_rehab_epis_plan,
                                 i_dt_current_timestamp => dt_current_timestamp,
                                 o_error                => o_error);
    
        update_notes_history(i_lang                 => i_lang,
                             i_prof                 => i_prof,
                             i_id_rehab_epis_plan   => i_id_rehab_epis_plan,
                             i_dt_current_timestamp => dt_current_timestamp,
                             o_error                => o_error);
    
        update_rehab_plan_history(i_lang                 => i_lang,
                                  i_prof                 => i_prof,
                                  i_id_rehab_epis_plan   => i_id_rehab_epis_plan,
                                  i_dt_current_timestamp => dt_current_timestamp,
                                  o_error                => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_area;

    /**
    * cancel_objective
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_objective
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_objective';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
        dt_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_rehab_epis_plan rehab_epis_plan.id_rehab_epis_plan%TYPE;
    
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
        dt_current_timestamp := current_timestamp;
    
        IF NOT pk_rehab_epis_plan_area.cancel_objective(i_lang                     => i_lang,
                                                        i_prof                     => i_prof,
                                                        i_id_rehab_epis_plan_area  => i_id_rehab_epis_plan_area,
                                                        dt_rehab_epis_plan_area_in => current_timestamp,
                                                        o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        SELECT repa.id_rehab_epis_plan
          INTO l_id_rehab_epis_plan
          FROM rehab_epis_plan_area repa
         WHERE repa.id_rehab_epis_plan_area = i_id_rehab_epis_plan_area;
    
        update_objective_history(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                                 i_dt_current_timestamp => dt_current_timestamp,
                                 o_error                => o_error);
    
        update_notes_history(i_lang                 => i_lang,
                             i_prof                 => i_prof,
                             i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                             i_dt_current_timestamp => dt_current_timestamp,
                             o_error                => o_error);
    
        update_rehab_plan_history(i_lang                 => i_lang,
                                  i_prof                 => i_prof,
                                  i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                                  i_dt_current_timestamp => dt_current_timestamp,
                                  o_error                => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_objective;

    /**
    * cancel_notes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_notes
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_notes IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_notes';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
        dt_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_rehab_epis_plan rehab_epis_plan.id_rehab_epis_plan%TYPE;
    
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        dt_current_timestamp := current_timestamp;
    
        IF NOT pk_rehab_epis_plan_notes.cancel_notes(i_lang                      => i_lang,
                                                     i_prof                      => i_prof,
                                                     i_id_rehab_epis_plan_notes  => i_id_rehab_epis_plan_notes,
                                                     dt_rehab_epis_plan_notes_in => dt_current_timestamp,
                                                     o_error                     => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        SELECT n.id_rehab_epis_plan
          INTO l_id_rehab_epis_plan
          FROM rehab_epis_plan_notes n
         WHERE n.id_rehab_epis_plan_notes = i_id_rehab_epis_plan_notes;
    
        update_objective_history(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                                 i_dt_current_timestamp => dt_current_timestamp,
                                 o_error                => o_error);
    
        update_notes_history(i_lang                 => i_lang,
                             i_prof                 => i_prof,
                             i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                             i_dt_current_timestamp => dt_current_timestamp,
                             o_error                => o_error);
    
        update_rehab_plan_history(i_lang                 => i_lang,
                                  i_prof                 => i_prof,
                                  i_id_rehab_epis_plan   => l_id_rehab_epis_plan,
                                  i_dt_current_timestamp => dt_current_timestamp,
                                  o_error                => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_notes;

    /**
    * get_all_hist_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 17:23:09
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_gen_info           OUT pk_types.cursor_type,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_hist_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_epis_plan.get_history_info(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                   o_info               => o_gen_info,
                                                   o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_area.get_all_hist_plan(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                         o_info               => o_info,
                                                         o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
        IF NOT pk_rehab_epis_plan_notes.get_all_hist_plan(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                          i_notes_type         => 'N',
                                                          o_notes              => o_notes,
                                                          o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_epis_plan_notes.get_all_hist_plan(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                          i_notes_type         => 'S',
                                                          o_notes              => o_suggest,
                                                          o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_hist_plan;

    /**
    * set_plan_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION set_plan_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_prof_cat_pl           IN table_number,
        i_id_episode               IN rehab_epis_plan.id_episode%TYPE,
        i_creat_date               IN VARCHAR2,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_plan_areas';
        e_controlled_error EXCEPTION;
        l_action_message     sys_message.desc_message%TYPE;
        l_error_message      sys_message.desc_message%TYPE;
        dt_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        dt_current_timestamp := current_timestamp;
        g_error              := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.set_general_info(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                              i_id_episode         => i_id_episode,
                                              i_id_prof_cat        => i_id_prof_cat_pl,
                                              i_creat_date         => i_creat_date,
                                              i_current_timestamp  => dt_current_timestamp,
                                              o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        IF NOT pk_rehab_plan.set_plan_areas(i_lang                     => i_lang,
                                            i_prof                     => i_prof,
                                            i_id_rehab_epis_plan       => i_id_rehab_epis_plan,
                                            i_id_rehab_plan_area       => i_id_rehab_plan_area,
                                            i_id_rehab_epis_plan_area  => i_id_rehab_epis_plan_area,
                                            i_current_situation        => i_current_situation,
                                            i_goals                    => i_goals,
                                            i_methodology              => i_methodology,
                                            i_time                     => i_time,
                                            i_flg_time_unit            => i_flg_time_unit,
                                            i_id_prof_cat              => i_id_prof_cat,
                                            i_id_rehab_epis_plan_sug   => i_id_rehab_epis_plan_sug,
                                            i_suggestions              => i_suggestions,
                                            i_id_rehab_epis_plan_notes => i_id_rehab_epis_plan_notes,
                                            i_notes                    => i_notes,
                                            i_current_timestamp        => dt_current_timestamp,
                                            o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_plan_info;

BEGIN
    -- Initialization
    --<Statement>;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_plan;
/
