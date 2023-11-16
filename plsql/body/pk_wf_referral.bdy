/*-- Last Change Revision: $Rev: 2027869 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_referral IS

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
    * <Function description>
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
    * @since   14-09-2010
    */
    /**
    * <Function description>
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
    * @since   14-09-2010
    */
    PROCEDURE add_all_for_transition
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        tc_id_workflow         IN wf_workflow.id_workflow%TYPE DEFAULT NULL,
        tc_id_status_begin     IN wf_status.id_status%TYPE DEFAULT NULL,
        tc_id_status_end       IN wf_status.id_status%TYPE DEFAULT NULL,
        tc_id_software         IN software.id_software%TYPE DEFAULT NULL,
        tc_id_institution      IN institution.id_institution%TYPE DEFAULT NULL,
        tc_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        tc_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        tc_function            IN wf_transition_config.FUNCTION%TYPE DEFAULT NULL,
        tc_rank                IN wf_transition_config.rank%TYPE DEFAULT NULL,
        tc_flg_permission      IN wf_transition_config.flg_permission%TYPE DEFAULT NULL,
        tc_id_category         IN category.id_category%TYPE DEFAULT NULL,
        t_flg_available        IN wf_transition.flg_available%TYPE DEFAULT NULL,
        sc_b_icon              IN wf_status_config.icon%TYPE DEFAULT NULL,
        sc_b_color             IN wf_status_config.color%TYPE DEFAULT NULL,
        sc_b_rank              IN wf_status_config.rank%TYPE DEFAULT NULL,
        sc_b_function          IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_b_flg_insert        IN wf_status_config.flg_insert%TYPE DEFAULT NULL,
        sc_b_flg_update        IN wf_status_config.flg_update%TYPE DEFAULT NULL,
        sc_b_flg_delete        IN wf_status_config.flg_delete%TYPE DEFAULT NULL,
        sc_b_flg_read          IN wf_status_config.flg_read%TYPE DEFAULT NULL,
        s_b_description        IN wf_status.description%TYPE DEFAULT NULL,
        s_b_icon               IN wf_status.icon%TYPE DEFAULT NULL,
        s_b_color              IN wf_status.color%TYPE DEFAULT NULL,
        s_b_rank               IN wf_status.rank%TYPE DEFAULT NULL,
        s_b_flg_available      IN wf_status.flg_available%TYPE DEFAULT NULL,
        sw_b_description       IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_b_flg_begin         IN wf_status_workflow.flg_begin%TYPE DEFAULT NULL,
        sw_b_flg_final         IN wf_status_workflow.flg_final%TYPE DEFAULT NULL,
        sw_b_flg_available     IN wf_status_workflow.flg_available%TYPE DEFAULT NULL,
        sc_e_icon              IN wf_status_config.icon%TYPE DEFAULT NULL,
        sc_e_color             IN wf_status_config.color%TYPE DEFAULT NULL,
        sc_e_rank              IN wf_status_config.rank%TYPE DEFAULT NULL,
        sc_e_function          IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_e_flg_insert        IN wf_status_config.flg_insert%TYPE DEFAULT NULL,
        sc_e_flg_update        IN wf_status_config.flg_update%TYPE DEFAULT NULL,
        sc_e_flg_delete        IN wf_status_config.flg_delete%TYPE DEFAULT NULL,
        sc_e_flg_read          IN wf_status_config.flg_read%TYPE DEFAULT NULL,
        s_e_description        IN wf_status.description%TYPE DEFAULT NULL,
        s_e_icon               IN wf_status.icon%TYPE DEFAULT NULL,
        s_e_color              IN wf_status.color%TYPE DEFAULT NULL,
        s_e_rank               IN wf_status.rank%TYPE DEFAULT NULL,
        s_e_flg_available      IN wf_status.flg_available%TYPE DEFAULT NULL,
        sw_e_description       IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_e_flg_begin         IN wf_status_workflow.flg_begin%TYPE DEFAULT NULL,
        sw_e_flg_final         IN wf_status_workflow.flg_final%TYPE DEFAULT NULL,
        sw_e_flg_available     IN wf_status_workflow.flg_available%TYPE DEFAULT NULL,
        wm_id_market           IN wf_workflow_market.id_market%TYPE DEFAULT NULL,
        ws_flg_available       IN wf_workflow_software.flg_available%TYPE DEFAULT NULL,
        w_internal_name        IN wf_workflow.internal_name%TYPE DEFAULT NULL,
        w_description          IN wf_workflow.description%TYPE DEFAULT NULL,
        print_translation_cod  IN BOOLEAN := FALSE
        
    ) IS
    
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
        o_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => '<FunctionName>');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => '<FunctionName>');
    
        add_all_for_status(i_lang                 => i_lang,
                           sc_id_workflow         => tc_id_workflow,
                           sc_id_status           => tc_id_status_begin,
                           sc_id_software         => tc_id_software,
                           sc_id_institution      => tc_id_institution,
                           sc_id_profile_template => tc_id_profile_template,
                           sc_id_functionality    => tc_id_functionality,
                           sc_id_category         => tc_id_category,
                           sc_icon                => sc_b_icon,
                           sc_color               => sc_b_color,
                           sc_rank                => sc_b_rank,
                           sc_function            => sc_b_function,
                           sc_flg_insert          => sc_b_flg_insert,
                           sc_flg_update          => sc_b_flg_update,
                           sc_flg_delete          => sc_b_flg_delete,
                           sc_flg_read            => sc_b_flg_read,
                           s_description          => s_b_description,
                           s_icon                 => s_b_icon,
                           s_color                => s_b_color,
                           s_rank                 => s_b_rank,
                           s_flg_available        => s_b_flg_available,
                           sw_description         => sw_b_description,
                           sw_flg_begin           => sw_b_flg_begin,
                           sw_flg_final           => sw_b_flg_final,
                           sw_flg_available       => sw_b_flg_available,
                           wm_id_market           => wm_id_market,
                           ws_id_software         => tc_id_software,
                           ws_flg_available       => ws_flg_available,
                           w_internal_name        => w_internal_name,
                           w_description          => w_description,
                           print_translation_cod  => print_translation_cod);
    
        add_all_for_status(i_lang                 => i_lang,
                           sc_id_workflow         => tc_id_workflow,
                           sc_id_status           => tc_id_status_end,
                           sc_id_software         => tc_id_software,
                           sc_id_institution      => tc_id_institution,
                           sc_id_profile_template => tc_id_profile_template,
                           sc_id_functionality    => tc_id_functionality,
                           sc_id_category         => tc_id_category,
                           sc_icon                => sc_e_icon,
                           sc_color               => sc_e_color,
                           sc_rank                => sc_e_rank,
                           sc_function            => sc_e_function,
                           sc_flg_insert          => sc_e_flg_insert,
                           sc_flg_update          => sc_e_flg_update,
                           sc_flg_delete          => sc_e_flg_delete,
                           sc_flg_read            => sc_e_flg_read,
                           s_description          => s_e_description,
                           s_icon                 => s_e_icon,
                           s_color                => s_e_color,
                           s_rank                 => s_e_rank,
                           s_flg_available        => s_e_flg_available,
                           sw_description         => sw_e_description,
                           sw_flg_begin           => sw_e_flg_begin,
                           sw_flg_final           => sw_e_flg_final,
                           sw_flg_available       => sw_e_flg_available,
                           wm_id_market           => wm_id_market,
                           ws_id_software         => tc_id_software,
                           ws_flg_available       => ws_flg_available,
                           w_internal_name        => w_internal_name,
                           w_description          => w_description,
                           print_translation_cod  => print_translation_cod);
    
        add_transition(i_lang                 => i_lang,
                       tc_id_workflow         => tc_id_workflow,
                       tc_id_status_begin     => tc_id_status_begin,
                       tc_id_status_end       => tc_id_status_end,
                       tc_id_software         => tc_id_software,
                       tc_id_institution      => tc_id_institution,
                       tc_id_profile_template => tc_id_profile_template,
                       tc_id_functionality    => tc_id_functionality,
                       tc_function            => tc_function,
                       tc_rank                => tc_rank,
                       tc_flg_permission      => tc_flg_permission,
                       tc_id_category         => tc_id_category,
                       t_flg_available        => t_flg_available,
                       print_translation_cod  => print_translation_cod);
    
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
                                              i_function    => 'get_list_find',
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'add_all_for_transition',
                                              o_error    => o_error);
    END add_all_for_transition;

    /**
    * <Function description>
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
    * @since   14-09-2010
    */
    PROCEDURE add_all_for_status
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        sc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        sc_id_status           IN wf_status.id_status%TYPE,
        sc_id_software         IN software.id_software%TYPE,
        sc_id_institution      IN institution.id_institution%TYPE,
        sc_id_profile_template IN profile_template.id_profile_template%TYPE,
        sc_id_functionality    IN sys_functionality.id_functionality%TYPE,
        sc_id_category         IN category.id_category%TYPE,
        sc_icon                IN wf_status_config.icon%TYPE,
        sc_color               IN wf_status_config.color%TYPE,
        sc_rank                IN wf_status_config.rank%TYPE,
        sc_function            IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_flg_insert          IN wf_status_config.flg_insert%TYPE,
        sc_flg_update          IN wf_status_config.flg_update%TYPE,
        sc_flg_delete          IN wf_status_config.flg_delete%TYPE,
        sc_flg_read            IN wf_status_config.flg_read%TYPE,
        s_description          IN wf_status.description%TYPE DEFAULT NULL,
        s_icon                 IN wf_status.icon%TYPE DEFAULT NULL,
        s_color                IN wf_status.color%TYPE DEFAULT NULL,
        s_rank                 IN wf_status.rank%TYPE DEFAULT NULL,
        s_flg_available        IN wf_status.flg_available%TYPE DEFAULT 'Y',
        sw_description         IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_flg_begin           IN wf_status_workflow.flg_begin%TYPE DEFAULT 'Y',
        sw_flg_final           IN wf_status_workflow.flg_final%TYPE DEFAULT 'Y',
        sw_flg_available       IN wf_status_workflow.flg_available%TYPE DEFAULT 'Y',
        wm_id_market           IN wf_workflow_market.id_market%TYPE DEFAULT 0,
        ws_id_software         IN software.id_software%TYPE DEFAULT NULL,
        ws_flg_available       IN wf_workflow_software.flg_available%TYPE DEFAULT NULL,
        w_internal_name        IN wf_workflow.internal_name%TYPE DEFAULT NULL,
        w_description          IN wf_workflow.description%TYPE DEFAULT NULL,
        print_translation_cod  IN BOOLEAN := FALSE
        
    ) IS
    
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        o_error          t_error_out;
    
        v_wf_status wf_status.code_status%TYPE;
    BEGIN
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'add_all_for_status');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'add_all_for_status');
    
        v_wf_status := 'WF_STATUS.CODE_STATUS.' || sc_id_status;
    
        pk_wf_workflow.merge_rec(i_lang          => i_lang,
                                 i_id_workflow   => sc_id_workflow,
                                 i_internal_name => w_internal_name,
                                 i_description   => w_description,
                                 o_error         => o_error);
    
        pk_wf_workflow_software.merge_rec(i_lang          => i_lang,
                                          i_id_workflow   => sc_id_workflow,
                                          i_id_software   => nvl(ws_id_software, sc_id_software),
                                          i_flg_available => ws_flg_available,
                                          o_error         => o_error);
    
        pk_wf_workflow_market.merge_rec(i_lang        => i_lang,
                                        i_id_market   => nvl(wm_id_market, 0),
                                        i_id_workflow => sc_id_workflow,
                                        o_error       => o_error);
    
        pk_wf_status.ins_rec(i_lang          => i_lang,
                             i_id_status     => sc_id_status,
                             i_description   => s_description,
                             i_icon          => nvl(s_icon, sc_icon),
                             i_color         => nvl(s_color, sc_color),
                             i_rank          => nvl(s_rank, sc_rank),
                             i_code_status   => v_wf_status,
                             i_flg_available => s_flg_available,
                             o_error         => o_error);
    
        pk_wf_status_workflow.merge_rec(i_lang          => i_lang,
                                        i_id_workflow   => sc_id_workflow,
                                        i_id_status     => sc_id_status,
                                        i_description   => sw_description,
                                        i_flg_begin     => sw_flg_begin,
                                        i_flg_final     => sw_flg_final,
                                        i_flg_available => sw_flg_available,
                                        o_error         => o_error);
    
        pk_wf_status_config.merge_rec(i_lang                => i_lang,
                                      i_id_workflow         => sc_id_workflow,
                                      i_id_status           => sc_id_status,
                                      i_id_software         => sc_id_software,
                                      i_id_institution      => sc_id_institution,
                                      i_id_profile_template => sc_id_profile_template,
                                      i_id_functionality    => sc_id_functionality,
                                      i_icon                => sc_icon,
                                      i_color               => sc_color,
                                      i_rank                => sc_rank,
                                      i_function            => sc_function,
                                      i_flg_insert          => sc_flg_insert,
                                      i_flg_update          => sc_flg_update,
                                      i_flg_delete          => sc_flg_delete,
                                      i_flg_read            => sc_flg_read,
                                      i_id_category         => sc_id_category,
                                      o_error               => o_error);
    
        IF print_translation_cod
        THEN
            dbms_output.put_line(v_wf_status);
        END IF;
    
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
                                              i_function    => 'get_list_find',
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'add_all_for_status',
                                              o_error    => o_error);
    END add_all_for_status;

    /**
    * <Function description>
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
    * @since   14-09-2010
    */
    PROCEDURE add_status
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        sc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        sc_id_status           IN wf_status.id_status%TYPE,
        sc_id_software         IN software.id_software%TYPE,
        sc_id_institution      IN institution.id_institution%TYPE,
        sc_id_profile_template IN profile_template.id_profile_template%TYPE,
        sc_id_functionality    IN sys_functionality.id_functionality%TYPE,
        sc_id_category         IN category.id_category%TYPE,
        sc_icon                IN wf_status_config.icon%TYPE,
        sc_color               IN wf_status_config.color%TYPE,
        sc_rank                IN wf_status_config.rank%TYPE,
        sc_function            IN wf_status_config.FUNCTION%TYPE DEFAULT NULL,
        sc_flg_insert          IN wf_status_config.flg_insert%TYPE,
        sc_flg_update          IN wf_status_config.flg_update%TYPE,
        sc_flg_delete          IN wf_status_config.flg_delete%TYPE,
        sc_flg_read            IN wf_status_config.flg_read%TYPE,
        s_description          IN wf_status.description%TYPE DEFAULT NULL,
        s_icon                 IN wf_status.icon%TYPE DEFAULT NULL,
        s_color                IN wf_status.color%TYPE DEFAULT NULL,
        s_rank                 IN wf_status.rank%TYPE DEFAULT NULL,
        s_flg_available        IN wf_status.flg_available%TYPE DEFAULT 'Y',
        sw_description         IN wf_status_workflow.description%TYPE DEFAULT NULL,
        sw_flg_begin           IN wf_status_workflow.flg_begin%TYPE DEFAULT 'Y',
        sw_flg_final           IN wf_status_workflow.flg_final%TYPE DEFAULT 'Y',
        sw_flg_available       IN wf_status_workflow.flg_available%TYPE DEFAULT 'Y',
        print_translation_cod  IN BOOLEAN := FALSE
        
    ) IS
    
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        o_error          t_error_out;
    
        v_wf_status wf_status.code_status%TYPE;
    BEGIN
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'add_all_for_status');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'add_all_for_status');
    
        v_wf_status := 'WF_STATUS.CODE_STATUS.' || sc_id_status;
    
        pk_wf_status.ins_rec(i_lang          => i_lang,
                             i_id_status     => sc_id_status,
                             i_description   => s_description,
                             i_icon          => nvl(s_icon, sc_icon),
                             i_color         => nvl(s_color, sc_color),
                             i_rank          => nvl(s_rank, sc_rank),
                             i_code_status   => v_wf_status,
                             i_flg_available => s_flg_available,
                             o_error         => o_error);
    
        pk_wf_status_workflow.merge_rec(i_lang          => i_lang,
                                        i_id_workflow   => sc_id_workflow,
                                        i_id_status     => sc_id_status,
                                        i_description   => sw_description,
                                        i_flg_begin     => sw_flg_begin,
                                        i_flg_final     => sw_flg_final,
                                        i_flg_available => sw_flg_available,
                                        o_error         => o_error);
    
        pk_wf_status_config.merge_rec(i_lang                => i_lang,
                                      i_id_workflow         => sc_id_workflow,
                                      i_id_status           => sc_id_status,
                                      i_id_software         => sc_id_software,
                                      i_id_institution      => sc_id_institution,
                                      i_id_profile_template => sc_id_profile_template,
                                      i_id_functionality    => sc_id_functionality,
                                      i_icon                => sc_icon,
                                      i_color               => sc_color,
                                      i_rank                => sc_rank,
                                      i_function            => sc_function,
                                      i_flg_insert          => sc_flg_insert,
                                      i_flg_update          => sc_flg_update,
                                      i_flg_delete          => sc_flg_delete,
                                      i_flg_read            => sc_flg_read,
                                      i_id_category         => sc_id_category,
                                      o_error               => o_error);
    
        IF print_translation_cod
        THEN
            dbms_output.put_line(v_wf_status);
        END IF;
    
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
                                              i_function    => 'get_list_find',
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'add_all_for_status',
                                              o_error    => o_error);
    END add_status;

    /**
    * <Function description>
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
    * @since   14-09-2010
    */
    PROCEDURE add_transition
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        tc_id_workflow         IN wf_workflow.id_workflow%TYPE,
        tc_id_status_begin     IN wf_status.id_status%TYPE,
        tc_id_status_end       IN wf_status.id_status%TYPE,
        tc_id_software         IN software.id_software%TYPE DEFAULT 0,
        tc_id_institution      IN institution.id_institution%TYPE DEFAULT 0,
        tc_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT 0,
        tc_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT 0,
        tc_function            IN wf_transition_config.FUNCTION%TYPE DEFAULT NULL,
        tc_rank                IN wf_transition_config.rank%TYPE DEFAULT 10,
        tc_flg_permission      IN wf_transition_config.flg_permission%TYPE DEFAULT 'Y',
        tc_id_category         IN category.id_category%TYPE DEFAULT 0,
        t_flg_available        IN wf_transition.flg_available%TYPE DEFAULT 'Y',
        print_translation_cod  IN BOOLEAN := FALSE
    ) IS
        e_controlled_error EXCEPTION;
        l_action_message  sys_message.desc_message%TYPE;
        l_error_message   sys_message.desc_message%TYPE;
        --v_code_transition wf_transition.code_transition%TYPE;
        o_error           t_error_out;
    BEGIN
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'add_transition');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'add_transition');
    
        --v_code_transition := 'WF_TRANSITION.CODE_TRANSITION.' || tc_id_workflow || '.' || tc_id_status_begin || '.' ||
        --                          tc_id_status_end;
    
        pk_wf_transition.ins_rec(i_lang            => i_lang,
                                 i_id_workflow     => tc_id_workflow,
                                 i_id_status_begin => tc_id_status_begin,
                                 i_id_status_end   => tc_id_status_end,
                                 --i_code_transition => v_code_transition,
                                 i_flg_available   => t_flg_available,
                                 o_error           => o_error);
    
        pk_wf_transition_config.ins_rec(i_lang                => i_lang,
                                        i_id_workflow         => tc_id_workflow,
                                        i_id_status_begin     => tc_id_status_begin,
                                        i_id_status_end       => tc_id_status_end,
                                        i_id_software         => tc_id_software,
                                        i_id_institution      => tc_id_institution,
                                        i_id_profile_template => tc_id_profile_template,
                                        i_id_functionality    => tc_id_functionality,
                                        i_function            => tc_function,
                                        i_rank                => tc_rank,
                                        i_flg_permission      => tc_flg_permission,
                                        i_id_category         => tc_id_category,
                                        o_error               => o_error);
    
        IF print_translation_cod
        THEN
            dbms_output.put_line('NAO ACTUALIZADO'); --v_code_transition);
        END IF;
    
        dbms_output.put_line('NAO ACTUALIZADO');
    
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
                                              i_function    => 'get_list_find',
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'add_transition',
                                              o_error    => o_error);
    END add_transition;
BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_referral;
/