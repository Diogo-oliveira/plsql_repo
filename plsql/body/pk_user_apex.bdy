/*-- Last Change Revision: $Rev: 1764749 $*/
/*-- Last Change by: $Author: luis.fernandes $*/
/*-- Date of last change: $Date: 2017-01-03 19:12:15 +0000 (ter, 03 jan 2017) $*/

CREATE OR REPLACE PACKAGE BODY pk_user_apex IS

  FUNCTION is_login_valid(p_username VARCHAR, p_password VARCHAR)
    RETURN NUMBER IS
    val    BOOLEAN;
    app_id NUMBER;
  
  BEGIN
  
    SELECT workspace_id
      INTO app_id
      FROM apex_applications
     WHERE application_id = 10008;
  
    apex_util.set_security_group_id(p_security_group_id => app_id);
  
    --apex_util.unexpire_workspace_account('PATRICIA.NEVES');
    val := apex_util.is_login_password_valid(p_username => p_username,
                                             p_password => p_password);
  
    RETURN sys.diutil.bool_to_int(val);
  
  END;

  FUNCTION get_user_institution_list(i_username IN user_institutions.user_name%TYPE)
    RETURN table_number IS
  
    o_inst_list table_number;
    o_error     t_error_out;
    RESULT      BOOLEAN;
  
  BEGIN
    -- Call the function
    RESULT := pk_user_apex.get_user_institution(i_username  => i_username,
                                                o_inst_list => o_inst_list,
                                                o_error     => o_error);
  
    RETURN o_inst_list;
  
  END;

  --> PRIVATE
  /* initialization environment local common vars */
  PROCEDURE init_vars IS
  BEGIN
    g_flg_available := 'Y';
    g_no            := 'N';
    g_active        := 'A';
    g_package_owner := 'ALERT_APEX_TOOLS';
    g_package_name  := 'PK_USER_APEX';
  END init_vars;
  --> PUBLIC

  /********************************************************************************************
  * Method that sets user restraining access to institutions configuration list
  *
  * @param i_username     Apex username
  * @param i_inst_list    Array of institution ids
  * @param o_error        Error info
  *
  * @result                      true if successful
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION set_user_institution(i_username  IN user_institutions.user_name%TYPE,
                                i_inst_list IN table_number,
                                o_error     OUT t_error_out) RETURN BOOLEAN IS
  BEGIN
    g_error := 'INSERT INSTITUTION RESTRITION LIST TO USER ' || i_username;
    FORALL i IN 1 .. i_inst_list.count
      INSERT INTO user_institutions
        (user_name, id_institution)
      VALUES
        (i_username, i_inst_list(i));
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      pk_alert_exceptions.process_error(1,
                                        SQLCODE,
                                        SQLERRM,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'SET_USER_INSTITUTION',
                                        o_error);
      pk_utils.undo_changes;
      pk_alert_exceptions.reset_error_state;
      RETURN FALSE;
  END set_user_institution;

  /********************************************************************************************
  * Method that delete user restraining access to institutions configuration list
  *
  * @param i_username     Apex username
  * @param i_inst_list    Array of institution ids
  * @param o_error        Error info
  *
  * @result                      true if successful
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION delete_user_institution(i_username  IN user_institutions.user_name%TYPE,
                                   i_inst_list IN table_number,
                                   o_error     OUT t_error_out)
    RETURN BOOLEAN IS
  BEGIN
    g_error := 'REMOVE INSTITUTION RESTRITION LIST TO USER ' || i_username;
    FORALL i IN 1 .. i_inst_list.count
      DELETE FROM user_institutions ui
       WHERE ui.user_name = i_username
         AND ui.id_institution = i_inst_list(i);
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      pk_alert_exceptions.process_error(1,
                                        SQLCODE,
                                        SQLERRM,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'DELETE_USER_INSTITUTION',
                                        o_error);
      pk_utils.undo_changes;
      pk_alert_exceptions.reset_error_state;
      RETURN FALSE;
  END delete_user_institution;

  /********************************************************************************************
  * Method that deletes institutions a user has access to
  *
  * @param i_lang         Language id
  * @param i_user_list    Apex username
  * @param o_error        Error info
  *
  * @result                      true if successful
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION delete_user_institutions(i_lang      IN NUMBER,
                                    i_user_list IN VARCHAR,
                                    o_error     OUT t_error_out)
    RETURN BOOLEAN IS
    l_user_list table_varchar := table_varchar();
  BEGIN
  
    l_user_list := pk_apex_common.string_to_table_varchar(i_user_list);
    g_error     := 'Remove list of institutions in user: ' || i_user_list;
    FORALL i IN 1 .. l_user_list.count
      DELETE FROM user_institutions ui
       WHERE ui.user_name = l_user_list(i);
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      pk_alert_exceptions.process_error(i_lang,
                                        SQLCODE,
                                        SQLERRM,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'DELETE_USER_INSTITUTIONS',
                                        o_error);
      RETURN FALSE;
  END delete_user_institutions;

  /********************************************************************************************
  * Method that gets user institutions configuration list access
  *
  * @param i_username    Apex username
  * @param o_inst_list   Institution List
  * @param o_error       Error info
  *
  * @result                      true if successful
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION get_user_institution(i_username  IN user_institutions.user_name%TYPE,
                                o_inst_list OUT table_number,
                                o_error     OUT t_error_out) RETURN BOOLEAN IS
  BEGIN
    g_error := 'GET INSTITUTION RESTRITION LIST TO USER ' || i_username;
    SELECT ui.id_institution BULK COLLECT
      INTO o_inst_list
      FROM user_institutions ui
     WHERE ui.user_name = i_username;
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      o_inst_list := table_number();
      pk_alert_exceptions.process_error(1,
                                        SQLCODE,
                                        SQLERRM,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'GET_USER_INSTITUTION',
                                        o_error);
      pk_utils.undo_changes;
      pk_alert_exceptions.reset_error_state;
      RETURN FALSE;
  END get_user_institution;

  /********************************************************************************************
  * Get List of institutions for a list of users
  *
  * @param i_lang        Language id
  * @param i_user        Apex username
  * @param o_inst_list   Institution List
  * @param o_error       Error info
  *
  * @result                      true if successful
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION get_users_institutions(i_lang      IN NUMBER,
                                  i_user      IN VARCHAR2,
                                  o_inst_list OUT table_number,
                                  o_error     OUT t_error_out)
    RETURN BOOLEAN IS
    l_user_list table_varchar := table_varchar();
  BEGIN
    l_user_list := pk_apex_common.string_to_table_varchar(i_user);
    g_error     := 'Get list of institutions for users: ' || i_user;
    SELECT ui.id_institution BULK COLLECT
      INTO o_inst_list
      FROM user_institutions ui
     WHERE ui.user_name IN (SELECT /*+dynamic_sampling (usr 2)*/
                             column_value
                              FROM TABLE(l_user_list) usr);
    RETURN TRUE;
  END get_users_institutions;

  /********************************************************************************************
  * Function that returns institution list of values
  *
  * @param i_username    Apex username
  * @param i_disp_desc   Null value display
  *
  * @result                      Structure with list of display-return pairs
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION get_user_inst_lov(i_username  IN user_institutions.user_name%TYPE,
                             i_disp_desc IN VARCHAR2) RETURN t_tbl_lov IS
    l_instit_list table_number := table_number();
    l_tbl_lov     t_tbl_lov := t_tbl_lov();
  
    l_error t_error_out;
    l_exception EXCEPTION;
  BEGIN
    IF NOT pk_user_apex.get_user_institution(i_username,
                                             l_instit_list,
                                             l_error) THEN
      RAISE l_exception;
    END IF;
    IF l_instit_list.count > 0 THEN
      SELECT t_rec_lov('get_user_inst_lov',
                       tbl.column_value,
                       tbl.disp_desc) BULK COLLECT
        INTO l_tbl_lov
        FROM (SELECT column_value,
                     pk_utils.get_institution_name(pk_utils.get_institution_language(column_value),
                                                   column_value) disp_desc
                FROM TABLE(l_instit_list) inst
              UNION
              SELECT -1 column_value, i_disp_desc disp_desc
                FROM dual) tbl;
    
    END IF;
    RETURN l_tbl_lov;
  EXCEPTION
    WHEN l_exception THEN
      pk_alert_exceptions.process_error(1,
                                        l_error.ora_sqlcode,
                                        l_error.ora_sqlerrm,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'get_user_inst_lov',
                                        l_error);
      RETURN l_tbl_lov;
    WHEN OTHERS THEN
      pk_alert_exceptions.process_error(1,
                                        SQLCODE,
                                        SQLERRM,
                                        g_error,
                                        g_package_owner,
                                        g_package_name,
                                        'get_user_inst_lov',
                                        l_error);
      RETURN l_tbl_lov;
  END get_user_inst_lov;

  /********************************************************************************************
  * Get users with same institution access
  *
  * @param i_inst_list    List of facilities
  * @param i_cur_user     Apex username
  *
  * @result                      Structure with list of display-return pairs
  *
  * @author                      RGM
  * @version                     2.6.3
  * @since                       2013/04/10
  ********************************************************************************************/
  FUNCTION get_institution_user_match(i_inst_list IN table_number,
                                      i_cur_user  IN VARCHAR2)
    RETURN table_varchar IS
    l_temp_user table_varchar := table_varchar();
    l_user_list table_varchar := table_varchar();
    l_aux_val   NUMBER := 0;
  
    l_aux_idx NUMBER := 1;
  BEGIN
    -- count institutions for each user with similar lists
  
    -- Get users with common institutions
    SELECT ui.user_name BULK COLLECT
      INTO l_temp_user
      FROM user_institutions ui
     WHERE ui.user_name != i_cur_user
       AND ui.id_institution IN
           (SELECT /*+dynamic_sampling (inst 2)*/
             column_value
              FROM TABLE(i_inst_list) inst)
     GROUP BY ui.user_name;
    FOR i IN 1 .. l_temp_user.count
    LOOP
      -- for each user found check the exact ammount of institutions (common lists)
      SELECT COUNT(ui.id_institution)
        INTO l_aux_val
        FROM user_institutions ui
       WHERE ui.user_name = l_temp_user(i)
       GROUP BY ui.user_name;
      -- if the institutions are the same then ad user to array and return to configuration
      IF l_aux_val = i_inst_list.count THEN
        l_user_list.extend;
        l_user_list(l_aux_idx) := l_temp_user(i);
        l_aux_idx := l_aux_idx + 1;
      END IF;
    END LOOP;
    -- add current user to list of configs
    l_user_list.extend;
    l_user_list(l_aux_idx) := i_cur_user;
  
    RETURN l_user_list;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN l_user_list;
  END get_institution_user_match;
BEGIN
  init_vars();
  pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_user_apex;
/
