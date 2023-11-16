/*-- Last Change Revision: $Rev: 641858 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-21 11:23:17 +0100 (ter, 21 set 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_status_config IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:39:44
    -- Purpose : API for table wf_status_config

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_status_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        o_error               OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'INSERT INTO (wf_status_config) i_id_workflow: ' || i_id_workflow || '; i_id_status: ' ||
                   i_id_status || '; i_id_software: ' || i_id_software || '; i_id_institution: ' || i_id_institution ||
                   '; i_id_profile_template: ' || i_id_profile_template || '; i_id_functionality: ' ||
                   i_id_functionality || '; i_icon: ' || to_char(i_icon) || '; i_color: ' || to_char(i_color) ||
                   '; i_rank: ' || i_rank || '; i_function: ' || to_char(i_function) || '; i_flg_insert: ' ||
                   to_char(i_flg_insert) || '; i_flg_update: ' || to_char(i_flg_update) || '; i_flg_delete: ' ||
                   to_char(i_flg_delete) || '; i_flg_read: ' || to_char(i_flg_read) || '; i_id_category: ' ||
                   i_id_category;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        INSERT INTO wf_status_config
            (id_workflow,
             id_status,
             id_software,
             id_institution,
             id_profile_template,
             id_functionality,
             icon,
             color,
             rank,
             FUNCTION,
             flg_insert,
             flg_update,
             flg_delete,
             flg_read,
             id_category)
        VALUES
            (i_id_workflow,
             i_id_status,
             i_id_software,
             i_id_institution,
             i_id_profile_template,
             i_id_functionality,
             i_icon,
             i_color,
             i_rank,
             i_function,
             i_flg_insert,
             i_flg_update,
             i_flg_delete,
             i_flg_read,
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
    * Update a record into table wf_status_config
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        o_error               OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'UPDATE INTO (wf_status_config) i_id_workflow: ' || i_id_workflow || '; i_id_status: ' ||
                   i_id_status || '; i_id_software: ' || i_id_software || '; i_id_institution: ' || i_id_institution ||
                   '; i_id_profile_template: ' || i_id_profile_template || '; i_id_functionality: ' ||
                   i_id_functionality || '; i_icon: ' || to_char(i_icon) || '; i_color: ' || to_char(i_color) ||
                   '; i_rank: ' || i_rank || '; i_function: ' || to_char(i_function) || '; i_flg_insert: ' ||
                   to_char(i_flg_insert) || '; i_flg_update: ' || to_char(i_flg_update) || '; i_flg_delete: ' ||
                   to_char(i_flg_delete) || '; i_flg_read: ' || to_char(i_flg_read) || '; i_id_category: ' ||
                   i_id_category;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        UPDATE wf_status_config
           SET icon       = nvl(i_icon, icon),
               color      = nvl(i_color, color),
               rank       = nvl(i_rank, rank),
               FUNCTION   = nvl(i_function, FUNCTION),
               flg_insert = nvl(i_flg_insert, flg_insert),
               flg_update = nvl(i_flg_update, flg_update),
               flg_delete = nvl(i_flg_delete, flg_delete),
               flg_read   = nvl(i_flg_read, flg_read)
         WHERE id_workflow = i_id_workflow
           AND id_status = i_id_status
           AND id_software = i_id_software
           AND id_institution = i_id_institution
           AND id_profile_template = i_id_profile_template
           AND id_functionality = i_id_functionality
           AND id_category = i_id_category;
    
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
    * Insert a record into table wf_status_config, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ICON    Status icon. Overrides WF_STATUS.ICON
    * @param  I_COLOR    Hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example: 0xC86464:0xFFFFFF:0xC86464:0xFFFFFF. Overrides WF_STATUS.COLOR
    * @param  I_RANK    Status rank. For ordering in status lists. Overrides WF_STATUS.RANK
    * @param  I_FUNCTION    This function returns status info based on other business rules
    * @param  I_FLG_INSERT    Y if has right to insert, N otherwise
    * @param  I_FLG_UPDATE    Y if has right to update, N otherwise
    * @param  I_FLG_DELETE    Y if has right to delete, N otherwise
    * @param  I_FLG_READ    Y if has right to read, N otherwise
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
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_icon                IN wf_status_config.icon%TYPE,
        i_color               IN wf_status_config.color%TYPE,
        i_rank                IN wf_status_config.rank%TYPE,
        i_function            IN wf_status_config.FUNCTION%TYPE,
        i_flg_insert          IN wf_status_config.flg_insert%TYPE,
        i_flg_update          IN wf_status_config.flg_update%TYPE,
        i_flg_delete          IN wf_status_config.flg_delete%TYPE,
        i_flg_read            IN wf_status_config.flg_read%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
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
                i_id_status           => i_id_status,
                i_id_software         => i_id_software,
                i_id_institution      => i_id_institution,
                i_id_profile_template => i_id_profile_template,
                i_id_functionality    => i_id_functionality,
                i_icon                => i_icon,
                i_color               => i_color,
                i_rank                => i_rank,
                i_function            => i_function,
                i_flg_insert          => i_flg_insert,
                i_flg_update          => i_flg_update,
                i_flg_delete          => i_flg_delete,
                i_flg_read            => i_flg_read,
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
                    i_id_status           => i_id_status,
                    i_id_software         => i_id_software,
                    i_id_institution      => i_id_institution,
                    i_id_profile_template => i_id_profile_template,
                    i_id_functionality    => i_id_functionality,
                    i_icon                => i_icon,
                    i_color               => i_color,
                    i_rank                => i_rank,
                    i_function            => i_function,
                    i_flg_insert          => i_flg_insert,
                    i_flg_update          => i_flg_update,
                    i_flg_delete          => i_flg_delete,
                    i_flg_read            => i_flg_read,
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
    * Get a record form table wf_status_config given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow identification
    * @param  I_ID_STATUS    Status identification
    * @param  I_ID_SOFTWARE    Software that can perform this action
    * @param  I_ID_INSTITUTION    Institution that can perform this action
    * @param  I_ID_PROFILE_TEMPLATE    Profile that can performe this action
    * @param  I_ID_FUNCTIONALITY    Functionality that can perform this action
    * @param  I_ID_CATEGORY    Professional category identifier
    *
    * @RETURN  The wf_status_config record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow         IN wf_status_config.id_workflow%TYPE,
        i_id_status           IN wf_status_config.id_status%TYPE,
        i_id_software         IN wf_status_config.id_software%TYPE,
        i_id_institution      IN wf_status_config.id_institution%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE
    ) RETURN wf_status_config%ROWTYPE IS
        l_wf_status_config wf_status_config%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_wf_status_config
          FROM wf_status_config
         WHERE id_workflow = i_id_workflow
           AND id_status = i_id_status
           AND id_software = i_id_software
           AND id_institution = i_id_institution
           AND id_profile_template = i_id_profile_template
           AND id_functionality = i_id_functionality
           AND id_category = i_id_category;
    
        RETURN l_wf_status_config;
    END get_rec;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_status_config;
/