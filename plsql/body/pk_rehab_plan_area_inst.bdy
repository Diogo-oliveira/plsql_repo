/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_plan_area_inst IS

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
    * @since   06-12-2010 17:38:26
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
    
        l_prof_cat      category.id_category%TYPE;
        l_prof_template profile_template.id_profile_template%TYPE;
    
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'Init get_ref_status_info WF=';
    
        l_prof_cat      := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_prof_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        OPEN o_actions FOR
            SELECT act.id_action,
                   act.id_parent,
                   LEVEL,
                   act.from_state,
                   act.to_state,
                   nvl(pk_message.get_message(i_lang, i_prof, act.code_action), act.code_action) desc_action,
                   act.icon,
                   decode(act.flg_default, 'D', 'Y', 'N') flg_default,
                   act.flg_status AS flg_active,
                   act.internal_name action,
                   act.rank,
                   rpa.id_rehab_plan_area,
                   nvl2(rpa.code_rehab_plan_area,
                        nvl(pk_translation.get_translation(i_lang, rpa.code_rehab_plan_area), rpa.code_rehab_plan_area),
                        nvl(pk_message.get_message(i_lang, i_prof, act.code_action), act.code_action)) desc_area
              FROM action act
              JOIN action_permission ap
                ON (ap.id_action = act.id_action AND ap.id_profile_template = l_prof_template AND
                   ap.id_category = l_prof_cat)
              LEFT JOIN rehab_plan_area_inst rpai
                ON (rpai.id_action = act.id_action)
              LEFT JOIN rehab_plan_area rpa
                ON (rpa.id_rehab_plan_area = rpai.id_rehab_plan_area)
             WHERE act.subject = i_subject
               AND (decode(rpai.id_institution, 0, i_prof.institution, rpai.id_institution) = i_prof.institution OR
                   (rpai.id_institution IS NULL AND rpa.id_rehab_plan_area IS NULL))
               AND (rpa.flg_available = 'Y' OR rpa.id_rehab_plan_area IS NULL)
               AND act.id_action NOT IN (SELECT ae.id_action
                                           FROM action_exception ae
                                          WHERE (ae.id_category = l_prof_cat OR ae.id_profile_template = l_prof_template OR
                                                ae.id_profissional = i_prof.id)
                                            AND (ae.id_software = i_prof.software OR ae.id_software = 0)
                                            AND ae.flg_available = 'Y'
                                            AND ae.flg_status = 'A')
            CONNECT BY PRIOR act.id_action = act.id_parent
             START WITH act.id_parent IS NULL
             ORDER BY LEVEL, act.rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_actions);
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
                                              i_function    => 'GET_REHAB_MENU_PLANS',
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REHAB_MENU_PLANS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rehab_menu_plans;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_plan_area_inst;
/
