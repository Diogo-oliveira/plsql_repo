/*-- Last Change Revision: $Rev: 1414766 $*/
/*-- Last Change by: $Author: nuno.neves $*/
/*-- Date of last change: $Date: 2012-11-23 10:07:25 +0000 (sex, 23 nov 2012) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_epis_plan IS

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
    * insert
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
    * @since   06-12-2010
    */
    FUNCTION ins
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        id_episode_in          IN rehab_epis_plan.id_episode%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_epis_plan.flg_status%TYPE DEFAULT NULL,
        id_professional_in     IN rehab_epis_plan.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_in  IN rehab_epis_plan.dt_rehab_epis_plan%TYPE DEFAULT NULL,
        dt_last_update_in      IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        id_rehab_epis_plan_out OUT rehab_epis_plan.id_rehab_epis_plan%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'ins';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        id_rehab_epis_plan_out := ts_rehab_epis_plan.next_key();
        ts_rehab_epis_plan.ins(id_rehab_epis_plan_in => id_rehab_epis_plan_out,
                               id_episode_in         => id_episode_in,
                               flg_status_in         => flg_status_in,
                               id_prof_create_in     => id_professional_in,
                               dt_rehab_epis_plan_in => dt_rehab_epis_plan_in,
                               dt_last_update_in     => NULL,
                               rows_out              => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_plan_hist.ins(id_rehab_epis_plan_hist_in => ts_rehab_epis_plan_hist.next_key(),
                                    id_rehab_epis_plan_in      => id_rehab_epis_plan_out,
                                    id_episode_in              => id_episode_in,
                                    flg_status_in              => flg_status_in,
                                    id_prof_create_in          => id_professional_in,
                                    dt_rehab_epis_plan_in      => dt_rehab_epis_plan_in,
                                    dt_last_update_in          => NULL,
                                    rows_out                   => rows_out);
    
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
                                              i_function    => 'ins',
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
                                              i_function => 'ins',
                                              o_error    => o_error);
            RETURN FALSE;
    END ins;

    /**
    * update
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
    * @since   06-12-2010 12:31:31
    */
    FUNCTION upd
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_rehab_epis_plan_in IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        id_episode_in         IN rehab_epis_plan.id_episode%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_epis_plan.flg_status%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_epis_plan.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_in IN rehab_epis_plan.dt_rehab_epis_plan%TYPE DEFAULT NULL,
        dt_last_update_in     IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'update';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_epis_plan.upd(id_rehab_epis_plan_in => id_rehab_epis_plan_in,
                               id_episode_in         => id_episode_in,
                               id_episode_nin        => FALSE,
                               flg_status_in         => flg_status_in,
                               flg_status_nin        => FALSE,
                               id_prof_create_in     => id_professional_in,
                               id_prof_create_nin    => FALSE,
                               dt_last_update_in     => dt_last_update_in,
                               dt_last_update_nin    => FALSE,
                               rows_out              => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_plan_hist.ins(id_rehab_epis_plan_hist_in => ts_rehab_epis_plan_hist.next_key(),
                                    id_rehab_epis_plan_in      => id_rehab_epis_plan_in,
                                    id_episode_in              => id_episode_in,
                                    flg_status_in              => flg_status_in,
                                    id_prof_create_in          => id_professional_in,
                                    dt_rehab_epis_plan_in      => dt_rehab_epis_plan_in,
                                    dt_last_update_in          => dt_last_update_in,
                                    rows_out                   => rows_out);
    
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
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'GET_GENERAL_INFO';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
        l_prof_cat category.id_category%TYPE;
        l_all_epis table_number;
    
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        g_error    := 'Call pk_prof_utils.get_categoyr i_prof.id=' || i_prof.id;
        l_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- para os assistentes sociais poderem ver o deep_nav da reabilitação
        g_error := 'Get L_ALL_EPIS';
        pk_alertlog.log_debug(g_error, g_package, l_sub_object_name);
        SELECT DISTINCT (id_episode) BULK COLLECT
          INTO l_all_epis
          FROM episode epis
         WHERE epis.id_visit = pk_episode.get_id_visit(i_id_episode);
    
        IF i_id_rehab_epis_plan IS NULL
        THEN
            OPEN o_info FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, dt_last_update, i_prof) dt_last_update,
                       pk_date_utils.date_send_tsz(i_lang, dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_last_update, i_prof) dt_last_update_desc,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan_desc,
                       flg_status,
                       pk_sysdomain.get_domain('REHAB_EPIS_PLAN.FLG_STATUS', flg_status, i_lang) flg_status_desc,
                       id_prof_create,
                       pk_prof_utils.get_name(i_lang, id_prof_create) prof_desc,
                       id_rehab_epis_plan,
                       id_episode,
                       pk_rehab_epis_plan_team.get_list_string(i_lang, i_prof, id_rehab_epis_plan) team
                  FROM rehab_epis_plan rep
                 WHERE ((nvl((SELECT DISTINCT ree.id_episode_origin
                               FROM rehab_epis_encounter ree
                              WHERE ree.id_episode_rehab = rep.id_episode),
                             rep.id_episode)) = (nvl((SELECT DISTINCT ree.id_episode_origin
                                                        FROM rehab_epis_encounter ree
                                                       WHERE ree.id_episode_rehab = i_id_episode),
                                                      i_id_episode)) OR
                       (rep.id_episode IN ((SELECT column_value
                                              FROM TABLE(l_all_epis))) AND l_prof_cat = 25))
                   AND flg_status = 'O';
        ELSE
            OPEN o_info FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, dt_last_update, i_prof) dt_last_update,
                       pk_date_utils.date_send_tsz(i_lang, dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_last_update, i_prof) dt_last_update_desc,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan_desc,
                       flg_status,
                       pk_sysdomain.get_domain('REHAB_EPIS_PLAN.FLG_STATUS', flg_status, i_lang) flg_status_desc,
                       id_prof_create,
                       pk_prof_utils.get_name(i_lang, id_prof_create) prof_desc,
                       id_rehab_epis_plan,
                       id_episode,
                       pk_rehab_epis_plan_team.get_list_string(i_lang, i_prof, id_rehab_epis_plan) team
                  FROM rehab_epis_plan
                 WHERE id_rehab_epis_plan = i_id_rehab_epis_plan;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_info);
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
            pk_types.open_my_cursor(o_info);
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
            OPEN o_info FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, rep.dt_last_update, i_prof) dt_last_update,
                       pk_date_utils.date_send_tsz(i_lang, rep.dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan,
                       pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof) dt_last_update_desc,
                       pk_date_utils.dt_chr_tsz(i_lang, rep.dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan_desc,
                       decode(rep.flg_status,
                              'O',
                              decode(ep.flg_status,
                                     'A',
                                     NULL,
                                     'P',
                                     NULL,
                                     pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof)),
                              pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof)) end_date,
                       rep.flg_status,
                       pk_sysdomain.get_domain('REHAB_EPIS_PLAN.FLG_STATUS', rep.flg_status, i_lang) flg_status_desc,
                       rep.id_prof_create,
                       pk_prof_utils.get_name(i_lang, rep.id_prof_create) prof_desc,
                       rep.id_rehab_epis_plan,
                       rep.id_episode,
                       pk_rehab_epis_plan_team.get_list_string(i_lang, i_prof, rep.id_rehab_epis_plan) team
                  FROM rehab_epis_plan rep
                  JOIN episode ep
                    ON (rep.id_episode = ep.id_episode)
                 WHERE ep.id_patient = i_id_patient
                 ORDER BY dt_rehab_epis_plan DESC;
        ELSE
            OPEN o_info FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, rep.dt_last_update, i_prof) dt_last_update,
                       pk_date_utils.date_send_tsz(i_lang, rep.dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan,
                       pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof) dt_last_update_desc,
                       pk_date_utils.dt_chr_tsz(i_lang, rep.dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan_desc,
                       decode(rep.flg_status,
                              'O',
                              decode(ep.flg_status,
                                     'A',
                                     NULL,
                                     'P',
                                     NULL,
                                     pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof)),
                              pk_date_utils.dt_chr_tsz(i_lang, rep.dt_last_update, i_prof)) end_date,
                       rep.flg_status,
                       pk_sysdomain.get_domain('REHAB_EPIS_PLAN.FLG_STATUS', rep.flg_status, i_lang) flg_status_desc,
                       rep.id_prof_create,
                       pk_prof_utils.get_name(i_lang, rep.id_prof_create) prof_desc,
                       rep.id_rehab_epis_plan,
                       rep.id_episode,
                       pk_rehab_epis_plan_team.get_list_string(i_lang, i_prof, rep.id_rehab_epis_plan) team
                  FROM rehab_epis_plan rep
                  JOIN episode ep
                    ON (rep.id_episode = ep.id_episode)
                 WHERE rep.id_episode = i_id_episode
                 ORDER BY dt_rehab_epis_plan;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_info);
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
            pk_types.open_my_cursor(o_info);
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
        dt_last_update_in    IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_epis_plan
           SET flg_status = 'C', dt_last_update = dt_last_update_in
         WHERE id_rehab_epis_plan = i_id_rehab_epis_plan;
    
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
    * get_history_info
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
    FUNCTION get_history_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_history_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rehab_m059       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M059');
        rehab_m060       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M060');
        rehab_m061       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M061');
        rehab_m062       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M062');
        rehab_m063       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M063');
        rehab_m053       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053');
        rehabs_m053      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053') || ' ';
        rehab_m054       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M054') || ' ';
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_info FOR
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, dt_last_update, i_prof) dt_last_update,
                           pk_date_utils.date_send_tsz(i_lang, dt_rehab_epis_plan, i_prof) dt_rehab_epis_plan,
                           nvl2(dt_last_update,
                                (pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                    nvl(dt_last_update, dt_rehab_epis_plan),
                                                                    i_prof) || rehab_m054 ||
                                pk_prof_utils.get_name(i_lang, id_prof_create)),
                                NULL) dt_last_update_desc,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                              (SELECT rep.dt_rehab_epis_plan
                                                                 FROM rehab_epis_plan rep
                                                                WHERE rep.id_rehab_epis_plan = i_id_rehab_epis_plan),
                                                              i_prof) dt_rehab_epis_plan_desc,
                           flg_status,
                           pk_sysdomain.get_domain('REHAB_EPIS_PLAN.FLG_STATUS', flg_status, i_lang) flg_status_desc,
                           id_prof_create,
                           pk_prof_utils.get_name(i_lang, id_prof_create) prof_desc,
                           id_rehab_epis_plan,
                           id_episode,
                           pk_rehab_epis_plan_team.get_hist_list_string(i_lang,
                                                                        i_prof,
                                                                        id_rehab_epis_plan,
                                                                        dt_rehab_epis_plan) team,
                           rehab_m059 || rehab_m053 lbl_creation,
                           rehab_m060 || rehab_m053 lbl_update,
                           rehab_m061 || rehab_m053 lbl_team,
                           rehab_m062 || rehab_m053 lbl_reg,
                           rehab_m063 lbl_title,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                              (SELECT rep.dt_rehab_epis_plan
                                                                 FROM rehab_epis_plan rep
                                                                WHERE rep.id_rehab_epis_plan = i_id_rehab_epis_plan),
                                                              i_prof) || rehab_m054 ||
                           pk_prof_utils.get_name(i_lang, id_prof_create) prof_creat,
                           id_rehab_epis_plan_hist id_plan_hist,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(dt_last_update, dt_rehab_epis_plan), i_prof) dt_upd_reg,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(dt_last_update, dt_rehab_epis_plan), i_prof) ||
                           rehab_m054 || pk_prof_utils.get_name(i_lang, id_prof_create) dt_reg_by_desc
                      FROM rehab_epis_plan_hist
                     WHERE id_rehab_epis_plan = i_id_rehab_epis_plan
                     ORDER BY dt_rehab_epis_plan DESC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_info);
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
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_history_info;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_epis_plan;
/