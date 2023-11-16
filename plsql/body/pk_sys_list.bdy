/*-- Last Change Revision: $Rev: 1987296 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-04-28 17:47:59 +0100 (qua, 28 abr 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_sys_list IS

    -- Log initialization.    
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_error VARCHAR2(1000 CHAR);

    g_package_owner VARCHAR2(50 CHAR) := 'ALERT';
    g_package_name  VARCHAR2(50 CHAR) := 'PK_SYS_LIST';

    g_available_y CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_available_n CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_market_all  CONSTANT market.id_market%TYPE := 0;

    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID, institution, software
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    * @param   O_SQL                      notes made in given interval
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_sys_list_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
        --Call internal function
        g_error := 'Call to pk_sys_list.get_sys_list_values_int';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'GET_SYS_LIST_VALUES');
    
        l_ret := pk_sys_list.get_sys_list_values_int(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_sys_list_group => i_id_sys_list_group,
                                                     i_internal_name     => NULL,
                                                     o_sql               => o_sql,
                                                     o_error             => l_error);
    
        IF NOT l_ret
        THEN
            pk_types.open_my_cursor(o_sql);
            o_error := l_error;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SYS_LIST_VALUES',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_sys_list_values;

    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_internal_name            List group internal name
    * @param   o_sql                      list of vlues of a list group
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN sys_list_group.internal_name%TYPE,
        o_sql           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
        --Call internal function
        g_error := 'Call to pk_sys_list.get_sys_list_values_int';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'GET_SYS_LIST_VALUES');
        l_ret := pk_sys_list.get_sys_list_values_int(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_sys_list_group => NULL,
                                                     i_internal_name     => i_internal_name,
                                                     o_sql               => o_sql,
                                                     o_error             => l_error);
    
        IF NOT l_ret
        THEN
            pk_types.open_my_cursor(o_sql);
            o_error := l_error;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SYS_LIST_VALUES',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_sys_list_values;

    FUNCTION get_market_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE DEFAULT NULL,
        i_internal_name     IN sys_list_group.internal_name%TYPE DEFAULT NULL
    ) RETURN market.id_market%TYPE IS
        l_count  PLS_INTEGER;
        l_market market.id_market%TYPE;
    BEGIN
        --Verify if exists market specific values 
        g_error := 'GET ID_MARKET';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'GET_MARKET_INT');
        BEGIN
            SELECT i.id_market, COUNT(1)
              INTO l_market, l_count
              FROM sys_list_group_rel tmp, sys_list_group slg, institution i
             WHERE ((slg.id_sys_list_group = i_id_sys_list_group AND i_id_sys_list_group IS NOT NULL) OR
                   (slg.internal_name = i_internal_name AND i_internal_name IS NOT NULL))
               AND tmp.id_sys_list_group = slg.id_sys_list_group
               AND tmp.flg_available = g_available_y
               AND i.id_institution = i_prof.institution
               AND tmp.id_market = i.id_market
             GROUP BY i.id_market;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
    
        --Id there's no market specific values, consider default values
        IF nvl(l_count, 0) = 0
        THEN
            l_market := g_market_all;
        END IF;
    
        RETURN l_market;
    END get_market_int;

    /*
    * Get list of values of a list group - INTERNAL
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    * @param   i_internal_name            List group internal name
    * @param   o_sql                      list of vlues of a list group
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_values_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        i_internal_name     IN sys_list_group.internal_name%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_lst_values t_table_sys_list;
        l_exception EXCEPTION;
    BEGIN
        IF i_id_sys_list_group IS NOT NULL
        THEN
            g_error := 'Call to get_sys_list_values_int by group id';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                 object_name     => g_package_name,
                                 sub_object_name => 'GET_SYS_LIST_VALUES_INT');
            l_tbl_lst_values := pk_sys_list.tf_sys_list_values(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_sys_list_group => i_id_sys_list_group);
        ELSIF i_internal_name IS NOT NULL
        THEN
            g_error := 'Call to get_sys_list_values_int by internal name';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                 object_name     => g_package_name,
                                 sub_object_name => 'GET_SYS_LIST_VALUES_INT');
            l_tbl_lst_values := pk_sys_list.tf_sys_list_values(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_internal_name => i_internal_name);
        ELSE
            g_error := 'A VALUE HAS TO BE GIVEN FOR ONE OF THE FOLLOWING VARIABLES: i_id_sys_list_group, i_internal_name';
            RAISE l_exception;
        END IF;
    
        --Get list of values of the list group
        g_error := 'Open cursor';
        alertlog.pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package_name,
                             sub_object_name => 'GET_SYS_LIST_VALUES_INT');
        OPEN o_sql FOR
            SELECT t.id_sys_list_group, t.internal_name, t.id_sys_list, t.desc_list, t.img_name, t.rank, t.flg_context
              FROM TABLE(l_tbl_lst_values) t
             ORDER BY t.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SYS_LIST_VALUES_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_sys_list_values_int;

    /*
    * Get the description of a list value
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   29-JAN-2010
    *
    */
    FUNCTION get_sys_list_value_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sys_list IN sys_list.id_sys_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc   pk_translation.t_desc_translation;
    BEGIN
        g_error := 'Get list description';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'GET_SYS_LIST_VALUE_DESC');
        SELECT pk_translation.get_translation(i_lang, sl.code_sys_list)
          INTO l_desc
          FROM sys_list sl
         WHERE sl.id_sys_list = i_id_sys_list;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_sys_list_value_desc;
    --
    /*
    * Get the description of a context flag
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     Professional ID
    * @param   i_grp_internal_name        Group internal name
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   11-07-2012
    *
    */
    FUNCTION get_sys_list_value_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SYS_LIST_VALUE_DESC';
        --
        l_desc   pk_translation.t_desc_translation;
    BEGIN
        g_error := 'Get list description';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT pk_translation.get_translation(i_lang, sl.code_sys_list)
          INTO l_desc
          FROM sys_list sl
          JOIN sys_list_group_rel slgr
            ON slgr.id_sys_list = sl.id_sys_list
          JOIN sys_list_group slg
            ON slg.id_sys_list_group = slgr.id_sys_list_group
         WHERE slg.internal_name = i_grp_internal_name
           AND slgr.flg_context = i_flg_context;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sys_list_value_desc;
    /*
    * Get id_sys_list_group of the given internal_name
    *
    * @param   i_internal_name            Internal group name
    *
    * @RETURN  id_sys_list_group
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION get_sys_list_group_int(i_internal_name sys_list_group.internal_name%TYPE)
        RETURN sys_list_group.id_sys_list_group%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SYS_LIST_GROUP_INT';
        l_sys_list_group sys_list_group.id_sys_list_group%TYPE;
    BEGIN
        g_error := 'VERIFY IF GROUP NAME "' || i_internal_name || '" EXISTS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
        SELECT slg.id_sys_list_group
              INTO l_sys_list_group
          FROM sys_list_group slg
         WHERE slg.internal_name = i_internal_name;
        EXCEPTION
            WHEN no_data_found THEN
                l_sys_list_group := NULL;
        END;
    
        RETURN l_sys_list_group;
    END get_sys_list_group_int;
    --
    /*
    * Get id_sys_list of the given internal_name
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_sys_list_group           Sys list group ID
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION get_id_sys_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sys_list_group IN sys_list_group_rel.id_sys_list_group%TYPE,
        i_flg_context    IN sys_list_group_rel.flg_context%TYPE
    ) RETURN sys_list_group_rel.id_sys_list%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ID_SYS_LIST';
        l_sys_list sys_list_group_rel.id_sys_list%TYPE;
        l_market   market.id_market%TYPE;
    BEGIN
        g_error := 'GET ID_MARKET';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_market := get_market_int(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_sys_list_group => i_sys_list_group,
                                   i_internal_name     => NULL);
    
        g_error := 'GET ID_SYS_LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT lgr.id_sys_list
          INTO l_sys_list
          FROM sys_list_group_rel lgr
         WHERE lgr.id_sys_list_group = i_sys_list_group
           AND lgr.id_market = l_market
           AND lgr.flg_context = i_flg_context;
    
        RETURN l_sys_list;
    EXCEPTION
        WHEN dup_val_on_index THEN
            g_error := 'MORE THEN ONE ID_SYS_LIST FOR THE SAME ID_GROUP/FLG_CONTEXT: ' || i_sys_list_group || '/' ||
                       i_flg_context || ';';
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
    END get_id_sys_list;
    --
    /*
    * Get id_sys_list of the given internal_name
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_grp_internal_name        Group internal name
    * @param   i_flg_context              Flag context
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION get_id_sys_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE
    ) RETURN sys_list_group_rel.id_sys_list%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ID_SYS_LIST';
        l_sys_list_group sys_list_group.id_sys_list_group%TYPE;
        l_sys_list       sys_list_group_rel.id_sys_list%TYPE := NULL;
    BEGIN
        g_error := 'GET ID_SYS_LIST_GROUP FOR INTERNAL_NAME: ' || i_grp_internal_name;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT slg.id_sys_list_group
              INTO l_sys_list_group
              FROM sys_list_group slg
             WHERE slg.internal_name = i_grp_internal_name;
        EXCEPTION
            WHEN no_data_found THEN
                alertlog.pk_alertlog.log_error(text            => 'INTERNAL GROUP NAME "' || i_grp_internal_name ||
                                                                  '" DOESN''T EXIST',
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                l_sys_list_group := NULL;
        END;
    
        g_error := 'GET ID_SYS_LIST FOR ID_SYS_LIST_GROUP: ' || to_char(l_sys_list_group);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_sys_list_group IS NOT NULL
        THEN
            l_sys_list := get_id_sys_list(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_sys_list_group => l_sys_list_group,
                                          i_flg_context    => i_flg_context);
        END IF;
    
        RETURN l_sys_list;
    END get_id_sys_list;
    --
    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE DEFAULT NULL,
        i_internal_name     IN sys_list_group.internal_name%TYPE DEFAULT NULL
    ) RETURN t_table_sys_list IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_SYS_LIST_VALUES_INT';
        l_tbl    t_table_sys_list;
        l_market market.id_market%TYPE;
    BEGIN
        g_error := 'GET ID_MARKET';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_market := get_market_int(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_sys_list_group => i_id_sys_list_group,
                                   i_internal_name     => i_internal_name);
    
        --Get list of values of the list group
        g_error := 'FILL SYS_LIST TABLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t_rec_sys_list(slg.id_sys_list_group,
                              slg.internal_name,
                              slgr.id_sys_list,
                              pk_translation.get_translation(i_lang, sl.code_sys_list),
                              sl.img_name,
                              slgr.rank,
                              slgr.flg_context,
                              sl.internal_name)
          BULK COLLECT
          INTO l_tbl
          FROM sys_list_group slg, sys_list sl, sys_list_group_rel slgr
         WHERE ((slg.id_sys_list_group = i_id_sys_list_group AND i_id_sys_list_group IS NOT NULL) OR
               (slg.internal_name = i_internal_name AND i_internal_name IS NOT NULL))
           AND slgr.id_sys_list_group = slg.id_sys_list_group
           AND slgr.flg_available = g_available_y
           AND slgr.id_market = l_market
           AND sl.id_sys_list = slgr.id_sys_list
         ORDER BY slgr.rank;
    
        RETURN l_tbl;
    END tf_sys_list_values_int;
    --
    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   I_ID_SYS_LIST_GROUP        List group ID 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN t_table_sys_list IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_SYS_LIST_VALUES';
    BEGIN
        g_error := 'GET SYS LIST VALUES. i_id_sys_list_group: ' || to_char(i_id_sys_list_group);
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN tf_sys_list_values_int(i_lang => i_lang, i_prof => i_prof, i_id_sys_list_group => i_id_sys_list_group);
    END tf_sys_list_values;
    --
    /*
    * Get list of values of a list group
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    * @param   i_internal_name            List group internal name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION tf_sys_list_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN sys_list_group.internal_name%TYPE
    ) RETURN t_table_sys_list IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_SYS_LIST_VALUES';
    BEGIN
        g_error := 'GET SYS LIST VALUES. i_internal_name: ' || i_internal_name;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN tf_sys_list_values_int(i_lang => i_lang, i_prof => i_prof, i_internal_name => i_internal_name);
    END tf_sys_list_values;
    --
    /*
    * Insert new group or update group description
    *
    * @param   i_sys_list_group           Primary key
    * @param   i_internal_name            List group internal name
    * @param   i_internal_desc            List group internal description
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   17-02-2010
    *
    */
    FUNCTION insert_into_sys_list_group
    (
        i_sys_list_group IN sys_list_group.id_sys_list_group%TYPE DEFAULT NULL,
        i_internal_name  IN sys_list_group.internal_name%TYPE,
        i_internal_desc  IN sys_list_group.internal_desc%TYPE DEFAULT NULL
    ) RETURN sys_list_group.id_sys_list_group%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'INSERT_INTO_SYS_LIST_GROUP';
        l_sys_list_group sys_list_group.id_sys_list_group%TYPE;
        l_rows_out       table_varchar;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET GROUP';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_sys_list_group IS NULL
        THEN
            IF i_internal_name IS NOT NULL
            THEN
                l_sys_list_group := get_sys_list_group_int(i_internal_name => i_internal_name);
            ELSE
                g_error := 'ID OR INTERNAL_NAME GRP ARE MANDATORY';
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                RAISE l_exception;
            END IF;
        ELSE
            l_sys_list_group := i_sys_list_group;
        END IF;
    
        IF l_sys_list_group IS NULL
        THEN
            g_error := 'INSERT NEW GROUP';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            l_sys_list_group := ts_sys_list_group.next_key();
        
            ts_sys_list_group.ins(id_sys_list_group_in => l_sys_list_group,
                                  internal_name_in     => i_internal_name,
                                  internal_desc_in     => i_internal_desc,
                                  rows_out             => l_rows_out);
        ELSE
            g_error := 'UPDATE EXISTING GROUP';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            ts_sys_list_group.upd(id_sys_list_group_in => l_sys_list_group,
                                  internal_name_in     => i_internal_name,
                                  internal_desc_in     => i_internal_desc,
                                  rows_out             => l_rows_out);
        END IF;
    
        RETURN l_sys_list_group;
    END insert_into_sys_list_group;
    --
    /*
    * Insert new list item and associate it to list group or update the translation/relation
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_sys_list                 NULL when is a new list item; otherwise the id_sys_list to ins/upd language
    * @param   i_list_item_desc           List item description
    * @param   i_img_name                 Image name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    FUNCTION insert_into_sys_list
    (
        i_lang           IN language.id_language%TYPE,
        i_sys_list       IN sys_list.id_sys_list%TYPE DEFAULT NULL,
        i_list_item_desc IN pk_translation.t_desc_translation,
        i_img_name       IN sys_list.img_name%TYPE DEFAULT NULL
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'INSERT_INTO_SYS_LIST';
        l_sys_list      sys_list.id_sys_list%TYPE;
        l_code_sys_list sys_list.code_sys_list%TYPE;
        l_code_label    VARCHAR2(30 CHAR) := 'SYS_LIST.CODE_SYS_LIST.';
    BEGIN
        IF i_sys_list IS NOT NULL
        THEN
            g_error := 'UPDT SYS_LIST IMG';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            l_sys_list      := i_sys_list;
            l_code_sys_list := l_code_label || to_char(l_sys_list);
        
            ts_sys_list.upd(id_sys_list_in => l_sys_list, img_name_in => i_img_name, img_name_nin => FALSE);
        ELSE
            g_error := 'INSERT NEW SYS_LIST';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            l_sys_list      := ts_sys_list.next_key();
            l_code_sys_list := l_code_label || to_char(l_sys_list);
        
            ts_sys_list.ins(id_sys_list_in   => l_sys_list,
                            code_sys_list_in => l_code_sys_list,
                            img_name_in      => i_img_name);
        END IF;
    
        g_error := 'INSERT TRANSLATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_code_sys_list,
                                               i_desc_trans => i_list_item_desc);
    
        RETURN l_sys_list;
    END insert_into_sys_list;
    --
    /*
    * Insert new list item and associate it to list group or update the translation/relation
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_sys_list_group           Sys list group ID
    * @param   i_grp_internal_name        List group internal name
    * @param   i_market                   Market ID
    * @param   i_sys_list                 Sys list ID
    * @param   i_flg_available            Availability
    * @param   i_rank                     Rank
    * @param   i_inst                     Institution ID
    * @param   i_soft                     Software ID
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   18-02-2010
    *
    */
    PROCEDURE insert_into_sys_list_group_rel
    (
        i_lang              IN language.id_language%TYPE DEFAULT NULL,
        i_sys_list_group    IN sys_list_group_rel.id_sys_list_group%TYPE DEFAULT NULL,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE DEFAULT NULL,
        i_market            IN sys_list_group_rel.id_market%TYPE,
        i_sys_list          IN sys_list_group_rel.id_sys_list%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE,
        i_flg_available     IN sys_list_group_rel.flg_available%TYPE DEFAULT 'Y',
        i_rank              IN sys_list_group_rel.rank%TYPE DEFAULT 0,
        i_inst              IN institution.id_institution%TYPE DEFAULT 0,
        i_soft              IN software.id_software%TYPE DEFAULT 0
    ) IS
        l_proc_name CONSTANT VARCHAR2(30 CHAR) := 'INSERT_INTO_SYS_LIST_GROUP_REL';
        l_sys_group_rel  sys_list_group_rel.id_sys_list_group_rel%TYPE;
        l_sys_list_group sys_list_group_rel.id_sys_list_group%TYPE;
        l_market         sys_list_group_rel.id_market%TYPE;
        l_rows_out       table_varchar;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET GROUP';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_proc_name);
        IF i_sys_list_group IS NULL
        THEN
            IF i_grp_internal_name IS NOT NULL
            THEN
                l_sys_list_group := get_sys_list_group_int(i_internal_name => i_grp_internal_name);
            ELSE
                g_error := 'ID OR INTERNAL_NAME GRP ARE MANDATORY';
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_proc_name);
                RAISE l_exception;
            END IF;
        ELSE
            l_sys_list_group := i_sys_list_group;
        END IF;
    
        g_error := 'GET ID_MARKET';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_proc_name);
        IF i_market IS NULL
        THEN
            l_market := get_market_int(i_lang              => i_lang,
                                       i_prof              => profissional(NULL, i_inst, i_soft),
                                       i_id_sys_list_group => l_sys_list_group);
        ELSE
            l_market := i_market;
        END IF;
    
        g_error := 'VERIFY IF RELATION ALREADY EXISTS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_proc_name);
        BEGIN
            SELECT slr.id_sys_list_group_rel
              INTO l_sys_group_rel
              FROM sys_list_group_rel slr
             WHERE slr.id_sys_list_group = l_sys_list_group
               AND slr.id_sys_list = i_sys_list
               AND slr.id_market = l_market;
        EXCEPTION
            WHEN no_data_found THEN
                l_sys_group_rel := NULL;
        END;
    
        IF l_sys_group_rel IS NULL
        THEN
            g_error := 'RELATION DOESN''T EXIST. INSERT NEW RELATION';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_proc_name);
            SELECT seq_sys_list_group_rel.nextval
              INTO l_sys_group_rel
              FROM dual;
        
            ts_sys_list_group_rel.ins(id_sys_list_group_rel_in => l_sys_group_rel,
                                      id_sys_list_group_in     => l_sys_list_group,
                                      id_sys_list_in           => i_sys_list,
                                      id_market_in             => l_market,
                                      flg_context_in           => i_flg_context,
                                      flg_available_in         => i_flg_available,
                                      rank_in                  => i_rank,
                                      rows_out                 => l_rows_out);
        ELSE
            g_error := 'RELATION EXISTs. UPDATE RELATION';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_proc_name);
            ts_sys_list_group_rel.upd(flg_available_in => i_flg_available,
                                      flg_context_in   => i_flg_context,
                                      flg_context_nin  => FALSE,
                                      rank_in          => i_rank,
                                      rank_nin         => FALSE,
                                      where_in         => 'id_sys_list_group_rel = ' || l_sys_group_rel,
                                      rows_out         => l_rows_out);
        END IF;
    END insert_into_sys_list_group_rel;

    /*
    * Verify if a ID_SYS_LIST is included in the specific group.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN BOOLEAN IS
    
        l_return BOOLEAN;
    BEGIN
        --Call internal function
        g_error := 'Call to pk_sys_list.check_sys_list_in_group_int';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'CHECK_SYS_LIST_IN_GROUP');
    
        IF NOT pk_sys_list.check_sys_list_in_group_int(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_sys_list       => i_id_sys_list,
                                                       i_id_sys_list_group => i_id_sys_list_group,
                                                       i_flg_market        => g_available_n)
        THEN
            l_return := FALSE;
        ELSE
            l_return := TRUE;
        END IF;
    
        RETURN l_return;
    END check_sys_list_in_group;

    /*
    * Verify if a ID_SYS_LIST is included in the specific group and market.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group_market
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE
    ) RETURN BOOLEAN IS
    
        l_return BOOLEAN;
    BEGIN
        --Call internal function
        g_error := 'Call to pk_sys_list.check_sys_list_in_group_int';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'CHECK_SYS_LIST_IN_GROUP_MARKET');
    
        IF NOT pk_sys_list.check_sys_list_in_group_int(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_sys_list       => i_id_sys_list,
                                                       i_id_sys_list_group => i_id_sys_list_group,
                                                       i_flg_market        => g_available_y)
        THEN
            l_return := FALSE;
        ELSE
            l_return := TRUE;
        END IF;
    
        RETURN l_return;
    END;

    /*
    * Verify if a ID_SYS_LIST is included in the specific group, by market (optional).-INTERNAL
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional ID
    * @param   I_ID_SYS_LIST        List Value ID to get the description
    * @param   i_id_sys_list_group  List group ID
    * @param   i_flg_market         Search if the list value is available to the specific market
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Batista
    * @version 1.0
    * @since   19-FEB-2010
    *
    */
    FUNCTION check_sys_list_in_group_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sys_list       IN sys_list.id_sys_list%TYPE,
        i_id_sys_list_group IN sys_list_group.id_sys_list_group%TYPE,
        i_flg_market        IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_count  PLS_INTEGER := 0;
        l_result BOOLEAN;
    
    BEGIN
    
        --Verify is value exists in group
        g_error := 'Verify is value exists in group';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'CHECK_SYS_LIST_IN_GROUP_INT');
        SELECT COUNT(1)
          INTO l_count
          FROM sys_list sl, sys_list_group gr, sys_list_group_rel rel
         WHERE sl.id_sys_list = i_id_sys_list
           AND gr.id_sys_list_group = i_id_sys_list_group
           AND rel.id_sys_list_group = gr.id_sys_list_group
           AND rel.id_sys_list = sl.id_sys_list
           AND ((i_flg_market = g_available_y
               
               AND rel.id_market IN ((SELECT i.id_market
                                         FROM institution i
                                        WHERE i.id_institution = i_prof.institution),
                                       0)) OR i_flg_market != g_available_y);
    
        IF nvl(l_count, 0) > 0
        THEN
            l_result := TRUE;
        ELSE
            l_result := FALSE;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'Exception raised. SQLERR: ' || SQLERRM;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => 'CHECK_SYS_LIST_IN_GROUP_INT');
            RETURN FALSE;
        
    END check_sys_list_in_group_int;

    /**********************************************************************************************
    * Get the flag context of a sys list in a sys list group
    *
    * @param        i_internal_name          Sys list group internal name
    * @param        i_sys_list               Sys listy id
    *
    * @return       The flag context
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        09-Jul-2010
    **********************************************************************************************/
    FUNCTION get_sys_list_context
    (
        i_internal_name IN sys_list_group.internal_name%TYPE,
        i_sys_list      IN sys_list_group_rel.id_sys_list%TYPE
    ) RETURN sys_list_group_rel.flg_context%TYPE IS
        l_context     sys_list_group_rel.flg_context%TYPE;
        l_tbl_context table_varchar;
    BEGIN
        pk_alertlog.log_info(text            => 'get sys list context i_internal_name:' || i_internal_name ||
                                                'i_sys_list:' || i_sys_list,
                             object_name     => g_package_name,
                             sub_object_name => 'GET_SYS_LIST_CONTEXT');
    
        SELECT slgr.flg_context
          BULK COLLECT
          INTO l_tbl_context
          FROM sys_list_group_rel slgr
         INNER JOIN sys_list_group slg
            ON slgr.id_sys_list_group = slg.id_sys_list_group
         WHERE slg.internal_name = i_internal_name
           AND slgr.id_sys_list = i_sys_list;
    
        IF l_tbl_context.count > 0
        THEN
            l_context := l_tbl_context(1);
        END IF;
        RETURN l_context;
    
    END get_sys_list_context;

    /**********************************************************************************************
    * Get the Id_Sys_List of a sys list given the internal_name
    *
    * @param        i_internal_name          Sys list group internal name
    *
    * @return       id_sys_list              id_sys_list matching the internal_name
    *
    * @author       Carlos Ferreira
    * @version      2.6.
    * @since        02-DEZ-2011
    **********************************************************************************************/
    FUNCTION get_id_sys_list(i_internal_name IN VARCHAR2) RETURN NUMBER IS
        l_id_sys_list table_number;
        l_return      NUMBER(24);
    BEGIN
    
        SELECT id_sys_list
          BULK COLLECT
          INTO l_id_sys_list
          FROM sys_list
         WHERE internal_name = i_internal_name;
    
        IF l_id_sys_list.count = 0
        THEN
            l_return := NULL;
        ELSE
            l_return := l_id_sys_list(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_sys_list;

-- Initialization
--    

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package_name);

END pk_sys_list;
/
