/*-- Last Change Revision: $Rev: 1414766 $*/
/*-- Last Change by: $Author: nuno.neves $*/
/*-- Date of last change: $Date: 2012-11-23 10:07:25 +0000 (sex, 23 nov 2012) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_epis_plan_area IS

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
    * @since   06-12-2010 15:05:15
    */
    FUNCTION ins
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        id_rehab_epis_plan_in       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE DEFAULT NULL,
        id_rehab_plan_area_in       IN rehab_epis_plan_area.id_rehab_plan_area%TYPE DEFAULT NULL,
        current_situation_in        IN rehab_epis_plan_area.current_situation%TYPE DEFAULT NULL,
        goals_in                    IN rehab_epis_plan_area.goals%TYPE DEFAULT NULL,
        methodology_in              IN rehab_epis_plan_area.methodology%TYPE DEFAULT NULL,
        time_in                     IN rehab_epis_plan_area.TIME%TYPE DEFAULT NULL,
        flg_time_unit_in            IN rehab_epis_plan_area.flg_time_unit%TYPE DEFAULT NULL,
        id_professional_in          IN rehab_epis_plan_area.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_area_in  IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        id_rehab_epis_plan_area_out OUT rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'INS';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        id_rehab_epis_plan_area_out := ts_rehab_epis_plan_area.next_key();
        ts_rehab_epis_plan_area.ins(id_rehab_epis_plan_area_in => id_rehab_epis_plan_area_out,
                                    id_rehab_epis_plan_in      => id_rehab_epis_plan_in,
                                    id_rehab_plan_area_in      => id_rehab_plan_area_in,
                                    current_situation_in       => current_situation_in,
                                    goals_in                   => goals_in,
                                    methodology_in             => methodology_in,
                                    time_in                    => time_in,
                                    flg_time_unit_in           => flg_time_unit_in,
                                    id_prof_create_in          => id_professional_in,
                                    dt_rehab_epis_plan_area_in => dt_rehab_epis_plan_area_in,
                                    flg_status_in              => 'Y',
                                    rows_out                   => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_AREA',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_pl_area_h.ins(id_rehab_epis_pl_area_h_in => ts_rehab_epis_pl_area_h.next_key(),
                                    id_rehab_epis_plan_area_in => id_rehab_epis_plan_area_out,
                                    current_situation_in       => current_situation_in,
                                    goals_in                   => goals_in,
                                    methodology_in             => methodology_in,
                                    time_in                    => time_in,
                                    flg_time_unit_in           => flg_time_unit_in,
                                    id_prof_create_in          => id_professional_in,
                                    dt_rehab_epis_plan_area_in => dt_rehab_epis_plan_area_in,
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
    * @since   06-12-2010 15:05:32
    */
    FUNCTION upd
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        id_rehab_epis_plan_area_in IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        current_situation_in       IN rehab_epis_plan_area.current_situation%TYPE DEFAULT NULL,
        goals_in                   IN rehab_epis_plan_area.goals%TYPE DEFAULT NULL,
        methodology_in             IN rehab_epis_plan_area.methodology%TYPE DEFAULT NULL,
        time_in                    IN rehab_epis_plan_area.TIME%TYPE DEFAULT NULL,
        flg_time_unit_in           IN rehab_epis_plan_area.flg_time_unit%TYPE DEFAULT NULL,
        id_professional_in         IN rehab_epis_plan_area.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
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
    
        ts_rehab_epis_plan_area.upd(id_rehab_epis_plan_area_in => id_rehab_epis_plan_area_in,
                                    current_situation_in       => current_situation_in,
                                    current_situation_nin      => FALSE,
                                    goals_in                   => goals_in,
                                    goals_nin                  => FALSE,
                                    methodology_in             => methodology_in,
                                    methodology_nin            => FALSE,
                                    time_in                    => time_in,
                                    time_nin                   => FALSE,
                                    flg_time_unit_in           => flg_time_unit_in,
                                    flg_time_unit_nin          => FALSE,
                                    id_prof_create_in          => id_professional_in,
                                    id_prof_create_nin         => FALSE,
                                    rows_out                   => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_AREA',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_pl_area_h.ins(id_rehab_epis_pl_area_h_in => ts_rehab_epis_pl_area_h.next_key(),
                                    id_rehab_epis_plan_area_in => id_rehab_epis_plan_area_in,
                                    current_situation_in       => current_situation_in,
                                    goals_in                   => goals_in,
                                    methodology_in             => methodology_in,
                                    time_in                    => time_in,
                                    flg_time_unit_in           => flg_time_unit_in,
                                    id_prof_create_in          => id_professional_in,
                                    dt_rehab_epis_plan_area_in => dt_rehab_epis_plan_area_in,
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_info FOR
            SELECT repa.current_situation,
                   repa.goals,
                   repa.methodology,
                   repa.TIME,
                   repa.flg_time_unit,
                   repa.TIME || ' ' ||
                   pk_sysdomain.get_domain('REHAB_EPIS_PLAN_AREA.FLG_TIME_UNIT', repa.flg_time_unit, i_lang) time_desc,
                   repa.id_prof_create,
                   pk_prof_utils.get_name(i_lang, repa.id_prof_create) prof_desc,
                   pk_date_utils.date_send_tsz(i_lang, repa.dt_rehab_epis_plan_area, i_prof) dt_rehab_epis_plan_area,
                   rpa.code_rehab_plan_area,
                   REPA.ID_REHAB_EPIS_PLAN_AREA,
                   pk_translation.get_translation(i_lang,rpa.code_rehab_plan_area) desc_area,
                   rpa.rank,
                   repa.id_rehab_plan_area,
                   'REHAB_PLAN' action,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      (SELECT MAX(h.dt_rehab_epis_plan_area)
                                                         FROM rehab_epis_pl_area_h h
                                                        WHERE h.id_rehab_epis_plan_area IN
                                                              (SELECT pa.id_rehab_epis_plan_area
                                                                 FROM rehab_epis_plan_area pa
                                                                WHERE pa.id_rehab_epis_plan = repa.id_rehab_epis_plan
                                                                  AND pa.id_rehab_plan_area = repa.id_rehab_plan_area)),
                                                      i_prof) dt_last_update_area
              FROM rehab_epis_plan_area repa
              JOIN rehab_plan_area rpa ON (repa.id_rehab_plan_area = rpa.id_rehab_plan_area)
             WHERE id_rehab_epis_plan = i_id_rehab_epis_plan
               AND flg_status = 'Y'
             ORDER BY rpa.rank, repa.id_rehab_plan_area, repa.dt_rehab_epis_plan_area;
    
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
    END get_all_plan;

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
    * @since   15-12-2010 08:30:15
    */
    FUNCTION cancel_area
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_area';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_epis_plan_area
           SET dt_rehab_epis_plan_area = dt_rehab_epis_plan_area_in, flg_status = 'N'
         WHERE id_rehab_plan_area = i_id_rehab_plan_area
           AND id_rehab_epis_plan = i_id_rehab_epis_plan
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
    * @since   15-12-2010 09:38:37
    */
    FUNCTION cancel_objective
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_area  IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_objective';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_epis_plan_area
           SET dt_rehab_epis_plan_area = dt_rehab_epis_plan_area_in, flg_status = 'N'
         WHERE id_rehab_epis_plan_area = i_id_rehab_epis_plan_area;
    
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_hist_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rehab_m064       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M064');
        rehab_m065       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M065');
        rehab_m066       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M066');
        rehab_m067       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M067');
        rehab_m042       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M042');
        rehab_m068       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M068');
        rehab_m069       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M069');
        rehab_m062       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M062');
        rehab_m053       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053');
        rehabs_m053      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053') || ' ';
        rehab_m054       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M054') || ' ';
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_info FOR
            SELECT master_tab.current_situation,
                   master_tab.goals,
                   master_tab.methodology,
                   master_tab.TIME,
                   master_tab.flg_time_unit,
                   master_tab.time_unit_desc,
                   master_tab.id_prof_create,
                   master_tab.prof_desc,
                   master_tab.dt_rehab_epis_plan_area,
                   master_tab.code_rehab_plan_area,
                   master_tab.plan_area_desc,
                   master_tab.rank,
                   master_tab.id_rehab_plan_area,
                   master_tab.id_rehab_epis_plan_area,
                   master_tab.plan_team,
                   master_tab.lbl_current_situation,
                   master_tab.lbl_gols,
                   master_tab.lbl_methodology,
                   master_tab.lbl_time,
                   master_tab.lbl_respon,
                   master_tab.lbl_reg,
                   master_tab.lbl_objective,
                   master_tab.id_plan_hist,
                   master_tab.objective_aux,
                   MAX(objective_aux) over(PARTITION BY id_rehab_epis_plan_area) || nvl2(master_tab.status_desc, ' - ' || master_tab.status_desc, '') objective_num,
                   master_tab.status_desc,
                   master_tab.flg_status,
                   master_tab.dt_rehab_epis_plan_area_desc,
                   master_tab.coelho
              FROM (SELECT repa.current_situation,
                           repa.goals,
                           repa.methodology,
                           repa.TIME,
                           repa.flg_time_unit,
                           pk_sysdomain.get_domain('REHAB_EPIS_PLAN_AREA.FLG_TIME_UNIT', repa.flg_time_unit, i_lang) time_unit_desc,
                           repa.id_prof_create,
                           pk_prof_utils.get_name(i_lang, repa.id_prof_create) prof_desc,
                           pk_date_utils.date_send_tsz(i_lang, repa.dt_rehab_epis_plan_area, i_prof) dt_rehab_epis_plan_area,
                           rpa.code_rehab_plan_area,
                           pk_translation.get_translation(i_lang, rpa.code_rehab_plan_area) plan_area_desc,
                           rpa.rank,
                           rep.id_rehab_plan_area,
                           repa.id_rehab_epis_plan_area,
                           pk_rehab_epis_plan_area_team.get_hist_list_string(i_lang,
                                                                             i_prof,
                                                                             repa.id_rehab_epis_plan_area,
                                                                             repa.dt_rehab_epis_plan_area) plan_team,
                           rehab_m064 || rehab_m053 lbl_current_situation,
                           rehab_m065 || rehab_m053 lbl_gols,
                           rehab_m066 || rehab_m053 lbl_methodology,
                           rehab_m042 || rehab_m053 lbl_time,
                           rehab_m068 || rehab_m053 lbl_respon,
                           rehab_m062 || rehabs_m053 ||
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, repa.dt_rehab_epis_plan_area, i_prof) ||
                           rehab_m054 || pk_prof_utils.get_name(i_lang, repa.id_prof_create) lbl_reg,
                           rehab_m069 lbl_objective,
                           NULL status_desc,
                           NULL flg_status,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, repa.dt_rehab_epis_plan_area, i_prof) dt_rehab_epis_plan_area_desc,
                           1 coelho,
                           (SELECT id_rehab_epis_plan_hist
                              FROM rehab_epis_plan_hist ph
                             WHERE ph.id_rehab_epis_plan = i_id_rehab_epis_plan
                               AND ph.dt_rehab_epis_plan = repa.dt_rehab_epis_plan_area) id_plan_hist,
                           1 objective_aux,
                           1 proviso
                      FROM rehab_epis_pl_area_h repa
                      JOIN rehab_epis_plan_area rep
                        ON (rep.id_rehab_epis_plan_area = repa.id_rehab_epis_plan_area)
                      JOIN rehab_plan_area rpa
                        ON (rep.id_rehab_plan_area = rpa.id_rehab_plan_area)
                     WHERE id_rehab_epis_plan = i_id_rehab_epis_plan) master_tab
             ORDER BY rank ASC, id_rehab_plan_area, coelho ASC, objective_num ASC;
    
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
    END get_all_hist_plan;

BEGIN
    -- Initialization
    --<Statement>;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
end PK_REHAB_EPIS_PLAN_AREA;
/