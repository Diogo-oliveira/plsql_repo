/*-- Last Change Revision: $Rev: 2028521 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_p1 IS

    FUNCTION get_p1_orig_instit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        o_p1_orig_inst OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_all_dest
    (
        i_lang    IN language.id_language%TYPE,
        o_p1_dest OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_dest
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        o_consult        OUT pk_types.cursor_type,
        o_analysis       OUT pk_types.cursor_type,
        o_exams          OUT pk_types.cursor_type,
        o_interv         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_resume
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        o_consult        OUT VARCHAR2,
        o_analysis       OUT VARCHAR2,
        o_exams          OUT VARCHAR2,
        o_interv         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_dest_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        i_flg_type       IN p1_dest_institution.flg_type%TYPE,
        o_p1_dest_inst   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_p1_spec_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_speciality    IN speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg_value        IN table_varchar,
        i_flg_default      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_spec_list
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_p1_spec_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_inst_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_cur     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_triage_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_triage_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_p1_dest_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst_orig IN table_number,
        i_id_inst_dest IN table_number,
        i_flg_type     IN table_varchar,
        i_flg_value    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_task
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_task    IN p1_task.desc_task%TYPE,
        i_purpose IN p1_task.flg_purpose%TYPE,
        o_p1_task OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_task_list
    (
        i_lang    IN language.id_language%TYPE,
        o_p1_task OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_task        IN p1_task.desc_task%TYPE,
        i_flg_purpose IN p1_task.flg_purpose%TYPE,
        o_p1_type     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_purpose_list
    (
        i_lang       IN language.id_language%TYPE,
        o_p1_purpose OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_p1_task
    (
        i_lang            IN language.id_language%TYPE,
        i_task            IN p1_task.desc_task%TYPE,
        i_old_flg_purpose IN p1_task.flg_purpose%TYPE,
        i_new_title       IN pk_translation.t_desc_translation,
        i_new_order       IN p1_task.rank%TYPE,
        i_new_flg_purpose IN p1_task.flg_purpose%TYPE,
        i_flg_type        IN table_varchar,
        i_flg_value       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_possible_task_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_inst_dest_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_spec         IN p1_speciality.id_speciality%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_p1_dest      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_spec_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_spec           IN p1_speciality.id_speciality%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_serv_spec_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        i_spec            IN p1_speciality.id_speciality%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_criteria_docs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_cur          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dest_inst_params
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_cur          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_destiny_resume_tasks
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_p1_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_task        IN table_varchar,
        i_flg_purpose IN table_varchar,
        i_flg_type    IN table_varchar,
        i_flg_value   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_document_tasks
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_details
    (
        i_lang           IN language.id_language%TYPE,
        i_id_speciality  IN speciality.id_speciality%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_cur            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_doc_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_speciality  IN speciality.id_speciality%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_spec_help   IN table_number,
        i_title          IN table_varchar,
        i_rank           IN table_number,
        i_text           IN table_varchar,
        i_flg_value      IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_func_list
    (
        i_lang         IN language.id_language%TYPE,
        o_p1_func_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_func_internal
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_dep_clin_serv   IN table_number,
        i_func            IN table_number,
        i_args            IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_func
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_dep_clin_serv   IN table_number,
        i_func            IN table_number,
        i_args            IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate DATE;
    g_error   VARCHAR2(2000);
    g_found   BOOLEAN;

    g_exam_freq   exam_dep_clin_serv.flg_type%TYPE;
    g_diag_freq   diagnosis_dep_clin_serv.flg_type%TYPE;
    g_drug_freq   drug_dep_clin_serv.flg_type%TYPE;
    g_interv_freq interv_dep_clin_serv.flg_type%TYPE;
    g_flg_avail   institution.flg_available%TYPE;
    g_active      prof_institution.flg_state%TYPE;

    g_cat_type_doc  category.flg_type%TYPE;
    g_cat_type_nurs category.flg_type%TYPE;
    g_cat_type_tec  category.flg_type%TYPE;
    g_cat_type_adm  category.flg_type%TYPE;
    g_cat_type_farm category.flg_type%TYPE;
    g_cat_type_oth  category.flg_type%TYPE;

    g_status_pdcs_s prof_dep_clin_serv.flg_status%TYPE;

    g_selected              VARCHAR2(1);
    g_reopen_epis           sys_config.value%TYPE;
    g_flg_available         VARCHAR2(1);
    g_exam_avail            exam.flg_available%TYPE;
    g_prof_flg_state_active professional.flg_state%TYPE;

    g_id_portugal country.id_country%TYPE;

    g_flg_icon_active   VARCHAR2(1);
    g_flg_icon_inactive VARCHAR2(1);

    g_exception EXCEPTION;

    g_bulk_fetch_rows NUMBER;

END pk_backoffice_p1;
/
