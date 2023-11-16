/*-- Last Change Revision: $Rev: 1918911 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-10-03 09:03:48 +0100 (qui, 03 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_epis_plan_team IS

    -- Private type declarations
    --TYPE < typename > IS < datatype >;

    -- Private constant declarations
    --< constantname > CONSTANT < datatype > := < VALUE >;

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * INS
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
    * @since   06-12-2010 15:29:14
    */
    FUNCTION ins
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        dt_rehab_epis_plan_team_in IN rehab_epis_plan_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        id_prof_cat_in             IN rehab_epis_plan_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in         IN rehab_epis_plan_team.id_prof_create%TYPE DEFAULT NULL,
        id_rehab_epis_plan_in      IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE DEFAULT NULL,
        id_rehab_epis_plan_team_in IN rehab_epis_plan_team.id_rehab_epis_plan_team%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'INS';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_epis_plan_team.ins(id_rehab_epis_plan_team_in => id_rehab_epis_plan_team_in,
                                    dt_rehab_epis_plan_team_in => dt_rehab_epis_plan_team_in,
                                    id_prof_cat_in             => id_prof_cat_in,
                                    id_rehab_epis_plan_in      => id_rehab_epis_plan_in,
                                    id_prof_create_in          => id_professional_in,
                                    flg_status_in              => 'Y',
                                    rows_out                   => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_TEAM',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
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
    END ins;

    /**
    * UPD
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
    * @since   06-12-2010 15:29:49
    */
    FUNCTION upd
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        id_rehab_epis_plan_team_in IN rehab_epis_plan_team.id_rehab_epis_plan_team%TYPE,
        id_prof_cat_in             IN rehab_epis_plan_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in         IN rehab_epis_plan_team.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_team_in IN rehab_epis_plan_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'UPD';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_epis_plan_team.upd(id_rehab_epis_plan_team_in  => id_rehab_epis_plan_team_in,
                                    id_prof_cat_in              => id_prof_cat_in,
                                    id_prof_create_in           => id_professional_in,
                                    id_prof_create_nin          => FALSE,
                                    dt_rehab_epis_plan_team_in  => dt_rehab_epis_plan_team_in,
                                    dt_rehab_epis_plan_team_nin => FALSE,
                                    rows_out                    => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_TEAM',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
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
    END upd;

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
    * @since   06-12-2010 19:03:13
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
    
        OPEN o_team FOR
            SELECT DISTINCT cat.id_category,
                            pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                            pk_prof_utils.get_name(i_lang, pc.id_professional) prof_name,
                            pc.id_prof_cat,
                            rept.id_rehab_epis_plan
              FROM rehab_epis_plan_team rept
              JOIN prof_cat pc
                ON (rept.id_prof_cat = pc.id_prof_cat)
              JOIN category cat
                ON (cat.id_category = pc.id_category)
             WHERE rept.id_rehab_epis_plan = i_id_rehab_epis_plan
               AND rept.flg_status = 'Y'
             ORDER BY cat_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_team);
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
            pk_types.open_my_cursor(o_team);
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
    * update_plan_area
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
    * @since   07-12-2010 14:30:13
    */
    FUNCTION update_plan_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'update_plan_area';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_epis_plan_team
           SET flg_status = 'N'
         WHERE id_rehab_epis_plan = i_id_rehab_epis_plan
           AND flg_status = 'Y';
    
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
    END update_plan_area;

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
        i_flg_status IN rehab_epis_plan.flg_status%TYPE DEFAULT NULL,
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
    
        IF i_id_episode IS NULL
        THEN
            OPEN o_teams FOR
                SELECT DISTINCT cat.id_category,
                                pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                                pk_prof_utils.get_name(i_lang, pc.id_professional) prof_name,
                                pc.id_prof_cat,
                                rept.id_rehab_epis_plan
                  FROM rehab_epis_plan_team rept
                  JOIN rehab_epis_plan rep
                    ON (rep.id_rehab_epis_plan = rept.id_rehab_epis_plan)
                  JOIN prof_cat pc
                    ON (rept.id_prof_cat = pc.id_prof_cat)
                  JOIN category cat
                    ON (cat.id_category = pc.id_category)
                  JOIN episode ep
                    ON (rep.id_episode = ep.id_episode)
                 WHERE ep.id_patient = i_id_patient
                   AND rept.flg_status = 'Y'
                 ORDER BY cat_desc;
        ELSE
            OPEN o_teams FOR
                SELECT DISTINCT cat.id_category,
                                pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                                pk_prof_utils.get_name(i_lang, pc.id_professional) prof_name,
                                pc.id_prof_cat,
                                rept.id_rehab_epis_plan
                  FROM rehab_epis_plan_team rept
                  JOIN rehab_epis_plan rep
                    ON (rep.id_rehab_epis_plan = rept.id_rehab_epis_plan)
                  JOIN prof_cat pc
                    ON (rept.id_prof_cat = pc.id_prof_cat)
                  JOIN category cat
                    ON (cat.id_category = pc.id_category)
                 WHERE (nvl((SELECT DISTINCT ree.id_episode_origin
                              FROM rehab_epis_encounter ree
                             WHERE ree.id_episode_rehab = rep.id_episode),
                            rep.id_episode)) = (nvl((SELECT DISTINCT ree.id_episode_origin
                                                      FROM rehab_epis_encounter ree
                                                     WHERE ree.id_episode_rehab = i_id_episode),
                                                    i_id_episode))
                   AND rept.flg_status = 'Y'
                   AND rep.flg_status = nvl(i_flg_status, rep.flg_status)
                 ORDER BY cat_desc;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_teams);
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
            pk_types.open_my_cursor(o_teams);
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
    * get_list_string
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
    FUNCTION get_list_string
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan.id_rehab_epis_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_sub_object_name VARCHAR2(20) := 'get_list_string';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        o_error          t_error_out;
        str_return       VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'Init get_ref_status_info WF=';
        SELECT listagg(pk_translation.get_translation(i_lang, code_category) || ': ' ||
                       pk_prof_utils.get_name(i_lang, id_professional),
                       '; ') within GROUP(ORDER BY 1)
          INTO str_return
          FROM rehab_epis_plan_team rept
          JOIN prof_cat pc
            ON (rept.id_prof_cat = pc.id_prof_cat)
          JOIN category cat
            ON (cat.id_category = pc.id_category)
         WHERE rept.id_rehab_epis_plan = i_id_rehab_epis_plan
           AND rept.flg_status = 'Y';
    
        RETURN str_return;
    
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
        
            RETURN '';
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN '';
    END get_list_string;

    /**
    * get_hist_list_string
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
    FUNCTION get_hist_list_string
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan      IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        i_dt_rehab_epis_plan_team IN rehab_epis_plan_team.dt_rehab_epis_plan_team%TYPE
    ) RETURN VARCHAR2 IS
    
        l_sub_object_name VARCHAR2(20) := 'get_hist_list_string';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        o_error          t_error_out;
        str_return       VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'Init get_ref_status_info WF=';
        SELECT listagg(pk_translation.get_translation(i_lang, code_category) || ': ' ||
                       pk_prof_utils.get_name(i_lang, id_professional),
                       '; ') within GROUP(ORDER BY 1)
          INTO str_return
          FROM (SELECT code_category,
                       pc.id_professional,
                       rept.dt_rehab_epis_plan_team,
                       rept.dt_rehab_epis_plan_team dt_aux
                  FROM rehab_epis_plan_team rept
                  JOIN prof_cat pc
                    ON (rept.id_prof_cat = pc.id_prof_cat)
                  JOIN category cat
                    ON (cat.id_category = pc.id_category)
                 WHERE id_rehab_epis_plan = i_id_rehab_epis_plan
                   AND rept.dt_rehab_epis_plan_team = i_dt_rehab_epis_plan_team
                 ORDER BY rept.dt_rehab_epis_plan_team DESC)
         WHERE dt_aux = dt_rehab_epis_plan_team;
    
        RETURN str_return;
    
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
        
            RETURN '';
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN '';
    END get_hist_list_string;

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN rehab_epis_plan_team.id_rehab_epis_plan_team%TYPE
    
     IS
        retval rehab_epis_plan_team.id_rehab_epis_plan_team%TYPE;
    
    BEGIN
        IF sequence_in IS NULL
        THEN
            SELECT seq_rehab_epis_plan_team.nextval
              INTO retval
              FROM dual;
        ELSE
            EXECUTE IMMEDIATE 'SELECT ' || sequence_in || '.NEXTVAL FROM dual'
                INTO retval;
        END IF;
        RETURN retval;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_name_in => 'SEQUENCE-GENERATION-FAILURE',
                                            name1_in      => 'SEQUENCE',
                                            value1_in     => nvl(sequence_in, 'seq_REHAB_EPIS_PLAN_AREA_TEAM'));
    END next_key;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_epis_plan_team;
/
