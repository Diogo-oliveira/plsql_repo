/*-- Last Change Revision: $Rev: 858016 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:24:08 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_plan_team IS

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
    * @since   06-12-2010 17:08:15
    */
    FUNCTION get_prof_by_cat
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
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
    
        IF i_id_category IS NULL
        THEN
            OPEN o_curs FOR
                SELECT DISTINCT cat.id_category,
                                pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                                rpt.rank
                  FROM rehab_plan_category_team rpt
                  JOIN category cat ON (rpt.id_category = cat.id_category)
                  JOIN prof_cat pc ON (pc.id_category = cat.id_category)
                 WHERE rpt.id_institution = i_prof.institution
                   AND pc.id_institution = rpt.id_institution
                 ORDER BY rank, cat_desc;
        ELSE
            OPEN o_curs FOR
                SELECT DISTINCT cat.id_category,
                                pk_translation.get_translation(i_lang, cat.code_category) cat_desc,
                                pk_prof_utils.get_name(i_lang, pc.id_professional) prof_name,
                                pc.id_prof_cat
                  FROM rehab_plan_category_team rpt
                  JOIN category cat ON (rpt.id_category = cat.id_category)
                  JOIN prof_cat pc ON (pc.id_category = cat.id_category)
                 WHERE rpt.id_institution = i_prof.institution
                   AND pc.id_institution = rpt.id_institution
                   AND cat.id_category = i_id_category
                 ORDER BY prof_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
        
            pk_types.open_my_cursor(o_curs);
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
            pk_types.open_my_cursor(o_curs);
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

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_plan_team;
/