/*-- Last Change Revision: $Rev: 2029006 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_task_type IS

    FUNCTION get_task_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_task_type_with_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_task_type_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN task_type.icon%TYPE;

    FUNCTION get_task_type_flg
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN task_type.flg_type%TYPE;

    FUNCTION get_task_type_code_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE insert_into_task_type
    (
        i_id_task_type           task_type.id_task_type%TYPE,
        i_id_task_type_parent    task_type.id_task_type_parent%TYPE DEFAULT NULL,
        i_code_task_type         task_type.code_task_type%TYPE DEFAULT NULL,
        i_icon                   task_type.icon%TYPE DEFAULT NULL,
        i_flg_type               task_type.flg_type%TYPE,
        i_flg_dependency_support task_type.flg_dependency_support%TYPE DEFAULT 'N',
        i_flg_episode_task       task_type.flg_episode_task%TYPE DEFAULT 'T',
        i_flg_modular_workflow   task_type.flg_modular_workflow%TYPE DEFAULT 'N'
        
    );

    /********************************************************************************************
    * set hidrics references in task_type table (to be executed only by DEFAULT)
    *
    * @author                                Vanessa Barsottelli
    * @since                                 09/02/2017
    ********************************************************************************************/
    PROCEDURE set_tt_hidric_references;

    g_error VARCHAR2(4000);

    g_log_object_owner VARCHAR2(50);
    g_log_object_name  VARCHAR2(50);

END;
/
