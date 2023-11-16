/*-- Last Change Revision: $Rev: 641858 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-21 11:23:17 +0100 (ter, 21 set 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_transition_config IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:37:50
    -- Purpose : API for table wf_transition_config

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_transition_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'INSERT INTO (wf_transition_config) i_id_workflow: ' || i_id_workflow || '; i_id_status_begin: ' ||
                   i_id_status_begin || '; i_id_status_end: ' || i_id_status_end || '; i_id_software: ' ||
                   i_id_software || '; i_id_institution: ' || i_id_institution || '; i_id_profile_template: ' ||
                   i_id_profile_template || '; i_id_functionality: ' || i_id_functionality || '; i_function: ' ||
                   to_char(i_function) || '; i_rank: ' || i_rank || '; i_flg_permission: ' || to_char(i_flg_permission) ||
                   '; i_id_category: ' || i_id_category;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        INSERT INTO wf_transition_config
            (id_workflow,
             id_status_begin,
             id_status_end,
             id_software,
             id_institution,
             id_profile_template,
             id_functionality,
             FUNCTION,
             rank,
             flg_permission,
             id_category)
        VALUES
            (i_id_workflow,
             i_id_status_begin,
             i_id_status_end,
             i_id_software,
             i_id_institution,
             i_id_profile_template,
             i_id_functionality,
             i_function,
             i_rank,
             i_flg_permission,
             i_id_category);
    
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
    * Update a record into table wf_transition_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'UPDATE INTO (wf_transition_config) i_id_workflow: ' || i_id_workflow || '; i_id_status_begin: ' ||
                   i_id_status_begin || '; i_id_status_end: ' || i_id_status_end || '; i_id_software: ' ||
                   i_id_software || '; i_id_institution: ' || i_id_institution || '; i_id_profile_template: ' ||
                   i_id_profile_template || '; i_id_functionality: ' || i_id_functionality || '; i_function: ' ||
                   to_char(i_function) || '; i_rank: ' || i_rank || '; i_flg_permission: ' || to_char(i_flg_permission) ||
                   '; i_id_category: ' || i_id_category;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        UPDATE wf_transition_config
           SET FUNCTION       = nvl(i_function, FUNCTION),
               rank           = nvl(i_rank, rank),
               flg_permission = nvl(i_flg_permission, flg_permission)
         WHERE id_workflow = i_id_workflow
           AND id_status_begin = i_id_status_begin
           AND id_status_end = i_id_status_end
           AND id_software = i_id_software
           AND id_institution = i_id_institution
           AND id_category = i_id_category
           AND id_profile_template = i_id_profile_template
           AND id_functionality = i_id_functionality;
    
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
    * Insert a record into table wf_transition_config, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_FUNCTION    This function returns flg_permission for this transition availability
    * @param  I_RANK    Transition rank
    * @param  I_FLG_PERMISSION    A - if this transition is allowed for the software, institution, profile_template and functionality, D - otherwise
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_function            IN wf_transition_config.FUNCTION%TYPE,
        i_rank                IN wf_transition_config.rank%TYPE,
        i_flg_permission      IN wf_transition_config.flg_permission%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        o_error               OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        g_error := 'ins_rec';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
    
        ins_rec(i_lang                => i_lang,
                i_id_workflow         => i_id_workflow,
                i_id_status_begin     => i_id_status_begin,
                i_id_status_end       => i_id_status_end,
                i_id_software         => i_id_software,
                i_id_institution      => i_id_institution,
                i_id_profile_template => i_id_profile_template,
                i_id_functionality    => i_id_functionality,
                i_function            => i_function,
                i_rank                => i_rank,
                i_flg_permission      => i_flg_permission,
                i_id_category         => i_id_category,
                o_error               => o_error);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            g_error := 'dup_val_on_index';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            g_error := 'upd_rec';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            upd_rec(i_lang                => i_lang,
                    i_id_workflow         => i_id_workflow,
                    i_id_status_begin     => i_id_status_begin,
                    i_id_status_end       => i_id_status_end,
                    i_id_software         => i_id_software,
                    i_id_institution      => i_id_institution,
                    i_id_profile_template => i_id_profile_template,
                    i_id_functionality    => i_id_functionality,
                    i_function            => i_function,
                    i_rank                => i_rank,
                    i_flg_permission      => i_flg_permission,
                    i_id_category         => i_id_category,
                    o_error               => o_error);
        
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
    * Get a record form table wf_transition_config given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_CATEGORY    Professional category identifier
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    *
    * @RETURN  The wf_transition_config record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_software         IN wf_transition_config.id_software%TYPE,
        i_id_institution      IN wf_transition_config.id_institution%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE
    ) RETURN wf_transition_config%ROWTYPE IS
        l_wf_transition_config wf_transition_config%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_wf_transition_config
          FROM wf_transition_config
         WHERE id_workflow = i_id_workflow
           AND id_status_begin = i_id_status_begin
           AND id_status_end = i_id_status_end
           AND id_software = i_id_software
           AND id_institution = i_id_institution
           AND id_category = i_id_category
           AND id_profile_template = i_id_profile_template
           AND id_functionality = i_id_functionality;
    
        RETURN l_wf_transition_config;
    END get_rec;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_transition_config;
/