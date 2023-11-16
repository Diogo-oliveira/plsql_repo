/*-- Last Change Revision: $Rev: 2027100 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_types AS

    PROCEDURE open_my_cursor(i_cursor IN OUT diagnosis_cur) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_epis_diagnosis,
                   NULL prof_category,
                   NULL id_epis_diagnosis_hist,
                   NULL id_diagnosis,
                   NULL id_alert_diagnosis,
                   NULL desc_diagnosis,
                   NULL date_target_initial,
                   NULL flg_with_notes,
                   NULL status_diagnosis,
                   NULL id_professional_diag,
                   NULL prof_name_diag,
                   NULL date_diag,
                   NULL date_target_diag,
                   NULL hour_target_diag,
                   NULL id_prof_confirmed,
                   NULL prof_name_conf,
                   NULL date_conf,
                   NULL date_target_conf,
                   NULL hour_target_conf,
                   NULL id_professional_cancel,
                   NULL prof_name_cancel,
                   NULL date_cancel,
                   NULL date_target_cancel,
                   NULL hour_target_cancel,
                   NULL id_prof_rulled_out,
                   NULL prof_name_rulled_out,
                   NULL date_rulled_out,
                   NULL date_target_rulled,
                   NULL hour_target_rulled,
                   NULL id_prof_base,
                   NULL prof_name_base,
                   NULL date_base,
                   NULL date_target_base,
                   NULL hour_target_base,
                   NULL icon_status,
                   NULL desc_status,
                   NULL icon_final_type,
                   NULL desc_final_type,
                   NULL final_type,
                   NULL date_order,
                   NULL notes,
                   NULL notes_cancel,
                   NULL id_cancel_reason,
                   NULL general_notes,
                   NULL avail_butt_cancel,
                   NULL rank,
                   NULL prof_spec_diag,
                   NULL prof_spec_conf,
                   NULL prof_spec_canc,
                   NULL prof_spec_rull,
                   NULL prof_spec_base,
                   NULL has_diff_diag,
                   NULL flg_is_cancer,
                   NULL ds_leaf_path
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_step) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_pre_hosp_form,
                   NULL id_pre_hosp_step,
                   NULL step_int_name,
                   NULL desc_step,
                   NULL flg_show_step_msg
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;
    --
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_section) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_pre_hosp_form,
                   NULL id_pre_hosp_step,
                   NULL id_pre_hosp_section,
                   NULL section_int_name,
                   NULL desc_section
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;
    --
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_field) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_pre_hosp_form,
                   NULL id_pre_hosp_step,
                   NULL id_pre_hosp_section,
                   NULL id_pre_hosp_field,
                   NULL field_int_name,
                   NULL desc_field,
                   NULL desc_new_field,
                   NULL flg_mandatory
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_status) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL val, NULL desc_val, NULL img_name, NULL flg_default
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_assoc_prob) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL data, NULL label, NULL flg_default, NULL flg_default_diag_cancer
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_discrim_child) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_triage,
                   NULL flg_reassess,
                   NULL id_triage_color,
                   NULL id_triage_color_other,
                   NULL color_text,
                   NULL acuity,
                   NULL id_triage_discriminator,
                   NULL desc_discriminator,
                   NULL flg_accepted_option,
                   NULL desc_accepted_option,
                   NULL flg_accuity_confirmation,
                   NULL flg_select_option,
                   NULL esi_level_header
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;
END;
/
