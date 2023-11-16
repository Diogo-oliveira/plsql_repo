/*-- Last Change Revision: $Rev: 1777047 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-03-28 15:36:05 +0100 (ter, 28 mar 2017) $*/

CREATE OR REPLACE PACKAGE BODY pk_viewer_checklist_ux IS

    /**
    * Returns value of checklist item for a checklist selected
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         Episode id
    * @param i_id_patient         Patient id
    * @param i_scope              Scope E-Episode, V-Visit, P-Patient
    * @param o_viewer_checklist   All items for the checklist
    * @param o_title              Title of checklist
    *
    * @author                Jorge Silva
    * @version               2.6.5
    * @since                 2015/02/06
    */
    FUNCTION get_viewer_checklist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_viewer_checklist IN viewer_checklist.id_viewer_checklist%TYPE,
        o_viewer_checklist    OUT pk_types.cursor_type,
        o_title               OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_VIEWER_CHECKLIST';
    BEGIN
        g_error := 'CALL pk_viewer_checklist.get_viewer_checklist';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_viewer_checklist.get_viewer_checklist(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_patient          => i_id_patient,
                                                        i_id_viewer_checklist => i_id_viewer_checklist,
                                                        o_viewer_checklist    => o_viewer_checklist,
                                                        o_title               => o_title,
                                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;

            RETURN FALSE;
    END get_viewer_checklist;

    /**
    * Returns all checklist configured
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_checklist_id
    * @param o_menu               All checklists
    *
    * @author                Jorge Silva
    * @version               2.6.5
    * @since                 2015/02/06
    */
    FUNCTION get_viewer_checklist_menu
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        --i_checklist_id IN viewer_checklist.id_viewer_checklist%TYPE,
        o_menu         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_VIEWER_CHECKLIST_MENU';
    BEGIN
        g_error := 'CALL pk_viewer_checklist.get_viewer_checklist_menu';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_viewer_checklist.get_viewer_checklist_menu(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             --i_checklist_id => i_checklist_id,
                                                             o_menu         => o_menu,
                                                             o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;

            RETURN FALSE;
    END get_viewer_checklist_menu;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_viewer_checklist_ux;
/
