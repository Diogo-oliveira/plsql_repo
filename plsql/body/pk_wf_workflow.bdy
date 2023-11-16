/*-- Last Change Revision: $Rev: 2027871 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_workflow IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:32:47
    -- Purpose : API for table wf_workflow

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'INSERT INTO (wf_workflow) i_id_workflow: ' || i_id_workflow || '; i_internal_name: ' ||
                   to_char(i_internal_name) || '; i_description: ' || to_char(i_description);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        INSERT INTO wf_workflow
            (id_workflow, internal_name, description)
        VALUES
            (i_id_workflow, i_internal_name, i_description);
    
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
    * Update a record into table wf_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'UPDATE INTO (wf_workflow) i_id_workflow: ' || i_id_workflow || '; i_internal_name: ' ||
                   to_char(i_internal_name) || '; i_description: ' || to_char(i_description);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        UPDATE wf_workflow
           SET internal_name = nvl(i_internal_name, internal_name), description = nvl(i_description, description)
         WHERE id_workflow = i_id_workflow;
    
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
    * Insert a record into table wf_workflow, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'ins_rec';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        ins_rec(i_lang          => i_lang,
                i_id_workflow   => i_id_workflow,
                i_internal_name => i_internal_name,
                i_description   => i_description,
                o_error         => o_error);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            g_error := 'dup_val_on_index';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            g_error := 'upd_rec';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            upd_rec(i_lang          => i_lang,
                    i_id_workflow   => i_id_workflow,
                    i_internal_name => i_internal_name,
                    i_description   => i_description,
                    o_error         => o_error);
        
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
    * Get a record form table wf_workflow given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow id
    *
    * @RETURN  The wf_workflow record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec(i_id_workflow IN wf_workflow.id_workflow%TYPE) RETURN wf_workflow%ROWTYPE IS
        l_wf_workflow wf_workflow%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_wf_workflow
          FROM wf_workflow
         WHERE id_workflow = i_id_workflow;
    
        RETURN l_wf_workflow;
    END get_rec;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_workflow;
/