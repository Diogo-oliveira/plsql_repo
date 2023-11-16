/*-- Last Change Revision: $Rev: 1860844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2018-08-28 17:43:54 +0100 (ter, 28 ago 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_epis_plan_notes IS

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
    * @since   06-12-2010 15:53:19
    */
    FUNCTION ins
    (
        i_lang                       IN LANGUAGE.id_language%TYPE,
        i_prof                       IN profissional,
        id_rehab_epis_plan_in        IN rehab_epis_plan_notes.id_rehab_epis_plan%TYPE DEFAULT NULL,
        flg_type_in                  IN rehab_epis_plan_notes.flg_type%TYPE DEFAULT NULL,
        notes_in                     IN rehab_epis_plan_notes.notes%TYPE DEFAULT NULL,
        id_professional_in           IN rehab_epis_plan_notes.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_notes_in  IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        id_rehab_epis_plan_notes_out OUT rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'INS';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        id_rehab_epis_plan_notes_out := ts_rehab_epis_plan_notes.next_key();
        ts_rehab_epis_plan_notes.ins(id_rehab_epis_plan_notes_in => id_rehab_epis_plan_notes_out,
                                     id_rehab_epis_plan_in       => id_rehab_epis_plan_in,
                                     flg_type_in                 => flg_type_in,
                                     notes_in                    => notes_in,
                                     id_prof_create_in           => id_professional_in,
                                     dt_rehab_epis_plan_notes_in => dt_rehab_epis_plan_notes_in,
                                     flg_status_in               => 'Y',
                                     rows_out                    => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_NOTES',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_pl_notes_h.ins(id_rehab_epis_pl_notes_h_in => ts_rehab_epis_pl_notes_h.next_key(),
                                     id_rehab_epis_plan_notes_in => id_rehab_epis_plan_notes_out,
                                     flg_type_in                 => flg_type_in,
                                     notes_in                    => notes_in,
                                     id_prof_create_in           => id_professional_in,
                                     dt_rehab_epis_plan_notes_in => dt_rehab_epis_plan_notes_in,
                                     rows_out                    => rows_out);
    
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
    * @since   06-12-2010 15:59:59
    */
    FUNCTION upd
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        id_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        flg_type_in                 IN rehab_epis_plan_notes.flg_type%TYPE DEFAULT NULL,
        notes_in                    IN rehab_epis_plan_notes.notes%TYPE DEFAULT NULL,
        id_professional_in          IN rehab_epis_plan_notes.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'UPD';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        ts_rehab_epis_plan_notes.upd(id_rehab_epis_plan_notes_in => id_rehab_epis_plan_notes_in,
                                     flg_type_in                 => flg_type_in,
                                     flg_type_nin                => FALSE,
                                     notes_in                    => notes_in,
                                     notes_nin                   => FALSE,
                                     id_prof_create_in           => id_professional_in,
                                     id_prof_create_nin          => FALSE,
                                     rows_out                    => rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_EPIS_PLAN_NOTES',
                                      i_rowids     => rows_out,
                                      o_error      => o_error);
    
        ts_rehab_epis_pl_notes_h.ins(id_rehab_epis_pl_notes_h_in => ts_rehab_epis_pl_notes_h.next_key(),
                                     id_rehab_epis_plan_notes_in => id_rehab_epis_plan_notes_in,
                                     flg_type_in                 => flg_type_in,
                                     notes_in                    => notes_in,
                                     id_prof_create_in           => id_professional_in,
                                     dt_rehab_epis_plan_notes_in => dt_rehab_epis_plan_notes_in,
                                     rows_out                    => rows_out);
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
    * @since   07-12-2010 17:27:25
    */
    FUNCTION get_all_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_notes_type         IN rehab_epis_plan_notes.flg_type%TYPE,
        o_notes              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_notes FOR
            SELECT id_prof_create,
                   id_rehab_epis_plan_notes,
                   pk_prof_utils.get_name(i_lang, id_prof_create) prof_desc,
                   pk_date_utils.date_send_tsz(i_lang, dt_rehab_epis_plan_notes, i_prof) dt_rehab_epis_plan_notes,
                   notes notes,
                   pk_sysdomain.get_domain('REHAB_EPIS_PLAN_NOTES.FLG_TYPE', flg_type, i_lang) desc_area,
                   flg_type,
                   decode(flg_type, 'N', 'REHAB_NOTES', 'S', 'REHAB_SUGGESTIONS') action
              FROM rehab_epis_plan_notes
             WHERE id_rehab_epis_plan = i_id_rehab_epis_plan
               AND flg_type = nvl(i_notes_type, flg_type)
               AND flg_status = 'Y'
             ORDER BY dt_rehab_epis_plan_notes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_notes);
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
            pk_types.open_my_cursor(o_notes);
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
    * @since   15-12-2010 08:30:15
    */
    FUNCTION cancel_notes
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_rehab_epis_plan_notes  IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        dt_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_notes';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rows_out         table_varchar;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        UPDATE rehab_epis_plan_notes
           SET dt_rehab_epis_plan_notes = dt_rehab_epis_plan_notes_in, flg_status = 'N'
         WHERE id_rehab_epis_plan_notes = i_id_rehab_epis_plan_notes;
    
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
    * @since   07-12-2010 17:27:25
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_notes_type         IN rehab_epis_plan_notes.flg_type%TYPE,
        o_notes              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_hist_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        rehab_m062       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M062');
        rehab_m070       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M070');
        rehab_m071       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M071');
        rehab_m072       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M072');
        rehab_m073       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M073');
        rehab_m053       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053');
        rehabs_m053      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M053') || ' ';
        rehab_m054       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'REHAB_M054') || ' ';
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_sub_object_name);
    
        OPEN o_notes FOR
            SELECT tab.*, MAX(note_num_aux) over(PARTITION BY id_rehab_epis_plan_notes) note_num
              FROM (SELECT nt.id_prof_create,
                           nt.id_rehab_epis_plan_notes,
                           pk_prof_utils.get_name(i_lang, nt.id_prof_create) prof_desc,
                           pk_date_utils.date_send_tsz(i_lang, nt.dt_rehab_epis_plan_notes, i_prof) dt_rehab_epis_plan_notes,
                           nt.notes,
                           pk_sysdomain.get_domain('REHAB_EPIS_PLAN_NOTES.FLG_TYPE', nt.flg_type, i_lang) desc_title,
                           nt.flg_type,
                           rehab_m062 || rehabs_m053 ||
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, nt.dt_rehab_epis_plan_notes, i_prof) || rehab_m054 ||
                           pk_prof_utils.get_name(i_lang, nt.id_prof_create) lbl_reg,
                           (SELECT id_rehab_epis_plan_hist
                              FROM rehab_epis_plan_hist ph
                             WHERE ph.id_rehab_epis_plan = i_id_rehab_epis_plan
                               AND ph.dt_rehab_epis_plan = nt.dt_rehab_epis_plan_notes) id_plan_hist,
                           decode(nt.flg_type, 'N', rehab_m070, rehab_m072) lbl_note_num,
                           decode(nt.flg_type, 'N', rehab_m070, rehab_m072) || rehab_m053 lbl_note,
                           NULL status_desc,
                           NULL flg_status,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, nt.dt_rehab_epis_plan_notes, i_prof) dt_rehab_epis_plan_notes_desc,
                           row_number() over(PARTITION BY n.id_rehab_epis_plan, nt.dt_rehab_epis_plan_notes ORDER BY nt.dt_rehab_epis_plan_notes ASC) AS note_num_aux
                      FROM rehab_epis_pl_notes_h nt
                      JOIN rehab_epis_plan_notes n
                        ON (nt.id_rehab_epis_plan_notes = n.id_rehab_epis_plan_notes)
                     WHERE n.id_rehab_epis_plan = i_id_rehab_epis_plan
                       AND nt.flg_type = nvl(i_notes_type, nt.flg_type)) tab
             ORDER BY note_num ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            pk_types.open_my_cursor(o_notes);
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
            pk_types.open_my_cursor(o_notes);
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
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
end PK_REHAB_EPIS_PLAN_NOTES;
/
