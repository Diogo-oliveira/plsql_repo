/*-- Last Change Revision: $Rev: 1918911 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-10-03 09:03:48 +0100 (qui, 03 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_epis_plan_area_team IS

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
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        id_rehab_epis_plan_area_in     IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE DEFAULT NULL,
        id_prof_cat_in                 IN rehab_ep_pl_ar_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in             IN rehab_ep_pl_ar_team.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_team_in     IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        id_rehab_epis_plan_area_team_i IN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'INS';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_ep_pl_ar_team.ins(id_rehab_ep_pl_ar_team_in  => id_rehab_epis_plan_area_team_i,
                                   id_rehab_epis_plan_area_in => id_rehab_epis_plan_area_in,
                                   id_prof_cat_in             => id_prof_cat_in,
                                   id_prof_create_in          => id_professional_in,
                                   dt_rehab_epis_plan_team_in => dt_rehab_epis_plan_team_in,
                                   flg_status_in              => 'Y',
                                   rows_out                   => rows_out);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EP_PL_AR_TEAM',
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
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        id_rehab_epis_plan_area_team_i IN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE,
        id_prof_cat_in                 IN rehab_ep_pl_ar_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in             IN rehab_ep_pl_ar_team.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_team_in     IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'UPD';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_ep_pl_ar_team.upd(id_rehab_ep_pl_ar_team_in   => id_rehab_epis_plan_area_team_i,
                                   id_prof_cat_in              => id_prof_cat_in,
                                   id_prof_create_in           => id_professional_in,
                                   id_prof_create_nin          => FALSE,
                                   dt_rehab_epis_plan_team_in  => dt_rehab_epis_plan_team_in,
                                   dt_rehab_epis_plan_team_nin => FALSE,
                                   rows_out                    => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EP_PL_AR_TEAM',
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
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'update_plan_area';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_ep_pl_ar_team
           SET flg_status = 'N'
         WHERE id_rehab_epis_plan_area = i_id_rehab_epis_plan_area
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

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE
    
     IS
        retval rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE;
    
    BEGIN
        IF sequence_in IS NULL
        THEN
            SELECT seq_rehab_ep_pl_ar_team.nextval
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
        i_id_rehab_epis_plan_area IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE,
        i_dt_rehab_epis_plan_team IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE
    ) RETURN VARCHAR2 IS
        l_sub_object_name VARCHAR2(20) := 'get_hist_list_string';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        o_error          t_error_out;
        str_return       VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'Init get_ref_status_info WF=';
        SELECT listagg(pk_prof_utils.get_name(i_lang, pc.id_professional), '; ') within GROUP(ORDER BY 1)
          INTO str_return
          FROM rehab_ep_pl_ar_team rept
          JOIN prof_cat pc
            ON (rept.id_prof_cat = pc.id_prof_cat)
          JOIN category cat
            ON (cat.id_category = pc.id_category)
         WHERE id_rehab_epis_plan_area = i_id_rehab_epis_plan_area
           AND dt_rehab_epis_plan_team = i_dt_rehab_epis_plan_team;
    
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

    /**
    * get_all_profs
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
    FUNCTION get_all_profs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_profs';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_obj_profs FOR
            SELECT cat.id_category,
                   pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                   pk_prof_utils.get_name(i_lang, pc.id_professional) desc_prof,
                   pc.id_prof_cat,
                   pc.id_professional,
                   rept.id_rehab_epis_plan_area
              FROM rehab_ep_pl_ar_team rept
              JOIN rehab_epis_plan_area repa
                ON (repa.id_rehab_epis_plan_area = rept.id_rehab_epis_plan_area)
              JOIN prof_cat pc
                ON (rept.id_prof_cat = pc.id_prof_cat)
              JOIN category cat
                ON (cat.id_category = pc.id_category)
             WHERE repa.id_rehab_epis_plan = i_id_rehab_epis_plan
               AND rept.flg_status = 'Y';
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
    END get_all_profs;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_epis_plan_area_team;
/
