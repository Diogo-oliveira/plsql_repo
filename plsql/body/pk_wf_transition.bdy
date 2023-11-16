/*-- Last Change Revision: $Rev: 782912 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2010-11-25 09:43:21 +0000 (qui, 25 nov 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_transition IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:36:41
    -- Purpose : API for table wf_transition

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_transition
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'INSERT INTO (wf_transition) i_id_workflow: ' || i_id_workflow || '; i_id_status_begin: ' ||
                   i_id_status_begin || '; i_id_status_end: ' || i_id_status_end --|| '; i_code_transition: ' || to_char(i_code_transition) 
                   || '; i_flg_available: ' || to_char(i_flg_available);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        INSERT INTO wf_transition
            (id_workflow,
             id_status_begin,
             id_status_end, --code_transition, 
             flg_available)
        VALUES
            (i_id_workflow,
             i_id_status_begin,
             i_id_status_end, --i_code_transition, 
             i_flg_available);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'ins_rec',
                                              o_error    => o_error);
    END ins_rec;

    /**
    * Update a record into table wf_transition
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'UPDATE INTO (wf_transition) i_id_workflow: ' || i_id_workflow || '; i_id_status_begin: ' ||
                   i_id_status_begin || '; i_id_status_end: ' || i_id_status_end --|| '; i_code_transition: ' || to_char(i_code_transition) 
                   || '; i_flg_available: ' || to_char(i_flg_available);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        UPDATE wf_transition
           SET --code_transition = nvl(i_code_transition, code_transition),
               flg_available   = nvl(i_flg_available, flg_available)
         WHERE id_workflow = i_id_workflow
           AND id_status_begin = i_id_status_begin
           AND id_status_end = i_id_status_end;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'upd_rec',
                                              o_error    => o_error);
    END upd_rec;

    /**
    * Insert a record into table wf_transition, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'ins_rec';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        ins_rec(i_lang            => i_lang,
                i_id_workflow     => i_id_workflow,
                i_id_status_begin => i_id_status_begin,
                i_id_status_end   => i_id_status_end,
                --i_code_transition => i_code_transition,
                i_flg_available   => i_flg_available,
                o_error           => o_error);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            g_error := 'dup_val_on_index';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            g_error := 'upd_rec';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            upd_rec(i_lang            => i_lang,
                    i_id_workflow     => i_id_workflow,
                    i_id_status_begin => i_id_status_begin,
                    i_id_status_end   => i_id_status_end,
                    --i_code_transition => i_code_transition,
                    i_flg_available   => i_flg_available,
                    o_error           => o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'merge_rec',
                                              o_error    => o_error);
    END merge_rec;

    /**
    * Get a record form table wf_transition given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    *
    * @RETURN  The wf_transition record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE
    ) RETURN wf_transition%ROWTYPE IS
        l_wf_transition wf_transition%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_wf_transition
          FROM wf_transition
         WHERE id_workflow = i_id_workflow
           AND id_status_begin = i_id_status_begin
           AND id_status_end = i_id_status_end;
    
        RETURN l_wf_transition;
    END get_rec;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_transition;
/