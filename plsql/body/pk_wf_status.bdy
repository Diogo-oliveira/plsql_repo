/*-- Last Change Revision: $Rev: 640247 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:01:16 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_wf_status IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:27:40
    -- Purpose : API for table wf_status

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_status
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:        0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
        o_error         OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        g_error := 'INSERT INTO (wf_status) i_id_status: ' || i_id_status || '; i_description: ' ||
                   to_char(i_description) || '; i_icon: ' || to_char(i_icon) || '; i_color: ' || to_char(i_color) ||
                   '; i_rank: ' || i_rank || '; i_code_status: ' || to_char(i_code_status) || '; i_flg_available: ' ||
                   to_char(i_flg_available);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'ins_rec');
    
        INSERT INTO wf_status
            (id_status, description, icon, color, rank, code_status, flg_available)
        VALUES
            (i_id_status, i_description, i_icon, i_color, i_rank, i_code_status, i_flg_available);
    
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
    * Update a record into table wf_status
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:        0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
        o_error         OUT t_error_out
    ) IS
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        g_error := 'UPDATE INTO (wf_status) i_id_status: ' || i_id_status || '; i_description: ' ||
                   to_char(i_description) || '; i_icon: ' || to_char(i_icon) || '; i_color: ' || to_char(i_color) ||
                   '; i_rank: ' || i_rank || '; i_code_status: ' || to_char(i_code_status) || '; i_flg_available: ' ||
                   to_char(i_flg_available);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'upd_rec');
    
        UPDATE wf_status
           SET description   = nvl(i_description, description),
               icon          = nvl(i_icon, icon),
               color         = nvl(i_color, color),
               rank          = nvl(i_rank, rank),
               code_status   = nvl(i_code_status, code_status),
               flg_available = nvl(i_flg_available, flg_available)
         WHERE id_status = i_id_status;
    
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
    * Insert a record into table wf_status, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_STATUS    Status id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_ICON    Default status icon
    * @param  I_COLOR    Default hexadecimal color code in the following format: GRID_BG_COLOR:GRID_FG_COLOR:OTHER_BG_COLOR:OTHER_FG_COLOR. For example:        0xC86464:0xFFFFFF:0xC86464:0xFFFFFF
    * @param  I_RANK    Default status rank. For ordering in status lists
    * @param  I_CODE_STATUS    Default status name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_status     IN wf_status.id_status%TYPE,
        i_description   IN wf_status.description%TYPE,
        i_icon          IN wf_status.icon%TYPE,
        i_color         IN wf_status.color%TYPE,
        i_rank          IN wf_status.rank%TYPE,
        i_code_status   IN wf_status.code_status%TYPE,
        i_flg_available IN wf_status.flg_available%TYPE,
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
                i_id_status     => i_id_status,
                i_description   => i_description,
                i_icon          => i_icon,
                i_color         => i_color,
                i_rank          => i_rank,
                i_code_status   => i_code_status,
                i_flg_available => i_flg_available,
                o_error         => o_error);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            g_error := 'dup_val_on_index';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            g_error := 'upd_rec';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'merge_rec');
        
            upd_rec(i_lang          => i_lang,
                    i_id_status     => i_id_status,
                    i_description   => i_description,
                    i_icon          => i_icon,
                    i_color         => i_color,
                    i_rank          => i_rank,
                    i_code_status   => i_code_status,
                    i_flg_available => i_flg_available,
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
    * Get a record form table wf_status given the primary key)
    *
    * @param  I_ID_STATUS    Status id
    *
    * @RETURN  The wf_status record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec(i_id_status IN wf_status.id_status%TYPE) RETURN wf_status%ROWTYPE IS
        l_wf_status wf_status%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_wf_status
          FROM wf_status
         WHERE id_status = i_id_status;
    
        RETURN l_wf_status;
    END get_rec;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wf_status;
/