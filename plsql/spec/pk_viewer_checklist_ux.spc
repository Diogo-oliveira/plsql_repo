/*-- Last Change Revision: $Rev: 1777043 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-03-28 15:34:32 +0100 (ter, 28 mar 2017) $*/

CREATE OR REPLACE PACKAGE pk_viewer_checklist_ux IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    --
    g_exception EXCEPTION;
    g_error VARCHAR2(4000 CHAR);
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

END pk_viewer_checklist_ux;
/
