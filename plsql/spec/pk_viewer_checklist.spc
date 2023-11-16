/*-- Last Change Revision: $Rev: 1887407 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2019-01-23 16:23:41 +0000 (qua, 23 jan 2019) $*/

CREATE OR REPLACE PACKAGE pk_viewer_checklist IS

    k_zero_value CONSTANT NUMBER := 0;
    g_pk_owner   CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

    g_diag_select diagnosis.flg_select%TYPE;

    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_checklist_icon_ongoing   VARCHAR2(4000) := 'WorkflowIcon';
    g_checklist_icon_completed VARCHAR2(4000) := 'CheckIcon';

    g_checklist_not_started VARCHAR2(1) := 'N';
    g_checklist_completed   VARCHAR2(1) := 'C';
    g_checklist_ongoing     VARCHAR2(1) := 'O';

    g_checklist_tt_completed VARCHAR2(30) := 'VIEWER_CHECKLIST_T001';
    g_checklist_tt_ongoing   VARCHAR2(30) := 'VIEWER_CHECKLIST_T002';

    g_checklist_color_white CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_checklist_color_red   CONSTANT VARCHAR2(200) := '0xCC0000';

    TYPE problem_dif IS RECORD(
        precaution_measures_b sys_message.desc_message%TYPE,
        precaution_measures_a sys_message.desc_message%TYPE,
        header_warning_b      sys_message.desc_message%TYPE,
        header_warning_a      sys_message.desc_message%TYPE,
        specialty_b           sys_message.desc_message%TYPE,
        specialty_a           sys_message.desc_message%TYPE,
        resolution_date_b     sys_message.desc_message%TYPE,
        resolution_date_a     sys_message.desc_message%TYPE,
        status_b              sys_message.desc_message%TYPE,
        status_a              sys_message.desc_message%TYPE,
        nature_b              sys_message.desc_message%TYPE,
        nature_a              sys_message.desc_message%TYPE,
        onset_b               sys_message.desc_message%TYPE,
        onset_a               sys_message.desc_message%TYPE,
        type_prob_b           sys_message.desc_message%TYPE,
        type_prob_a           sys_message.desc_message%TYPE,
        problem_b             sys_message.desc_message%TYPE,
        problem_a             sys_message.desc_message%TYPE,
        notes_b               sys_message.desc_message%TYPE,
        notes_a               sys_message.desc_message%TYPE,
        cancel_notes_b        sys_message.desc_message%TYPE,
        cancel_notes_a        sys_message.desc_message%TYPE,
        cancel_reason_b       sys_message.desc_message%TYPE,
        cancel_reason_a       sys_message.desc_message%TYPE,
        registered_b          sys_message.desc_message%TYPE,
        registered_a          sys_message.desc_message%TYPE,
        create_time           sys_message.desc_message%TYPE,
        cancel_prof_b         sys_message.desc_message%TYPE,
        cancel_prof_a         sys_message.desc_message%TYPE,
        cancel_date_b         sys_message.desc_message%TYPE,
        cancel_date_a         sys_message.desc_message%TYPE,
        record_origin_b       sys_message.desc_message%TYPE,
        record_origin_a       sys_message.desc_message%TYPE,
        complications_b       sys_message.desc_message%TYPE,
        complications_a       sys_message.desc_message%TYPE);

    TYPE problem_dif_table IS TABLE OF problem_dif INDEX BY BINARY_INTEGER;

    TYPE problem_type IS RECORD(
        problem             sys_message.desc_message%TYPE,
        precaution_measures sys_message.desc_message%TYPE,
        header_warning      sys_message.desc_message%TYPE,
        type_prob           sys_message.desc_message%TYPE,
        onset               sys_message.desc_message%TYPE,
        id_habit            sys_message.desc_message%TYPE,
        nature              sys_message.desc_message%TYPE,
        specialty           sys_message.desc_message%TYPE,
        status              sys_message.desc_message%TYPE,
        resolution_date     sys_message.desc_message%TYPE,
        notes               sys_message.desc_message%TYPE,
        cancel_reason       sys_message.desc_message%TYPE,
        cancel_notes        sys_message.desc_message%TYPE,
        registered          sys_message.desc_message%TYPE,
        create_time         sys_message.desc_message%TYPE,
        cancel_prof         sys_message.desc_message%TYPE,
        cancel_date         sys_message.desc_message%TYPE,
        record_origin       sys_message.desc_message%TYPE,
        complications       sys_message.desc_message%TYPE);

    -- Joana  Barroso: 2008/11/14 - TYPE utilizado para retornar informacao de get_pat_problem
    TYPE pat_problem_rec IS RECORD(
        id                      NUMBER(24),
        id_problem              NUMBER(24),
        TYPE                    VARCHAR2(2),
        dt_problem2             VARCHAR2(200),
        dt_problem              VARCHAR2(50),
        dt_problem_to_print     VARCHAR2(50),
        desc_probl              VARCHAR2(4000),
        title                   VARCHAR2(4000),
        flg_source              VARCHAR2(2),
        dt_order                VARCHAR2(14),
        flg_status              VARCHAR2(2),
        rank_type               NUMBER(6),
        rank_cancelled          NUMBER(1),
        rank_area               NUMBER(6),
        flg_cancel              VARCHAR2(2),
        desc_status             VARCHAR2(200),
        desc_nature             VARCHAR2(200),
        rank_status             NUMBER(6),
        rank_nature             NUMBER(6),
        flg_nature              VARCHAR2(2),
        title_notes             VARCHAR2(4000),
        prob_notes              VARCHAR2(4000),
        title_canceled          VARCHAR2(4000),
        id_prob                 NUMBER(24),
        viewer_category         VARCHAR2(4000),
        viewer_category_desc    VARCHAR2(4000),
        viewer_id_prof          NUMBER(24),
        viewer_id_epis          NUMBER(24),
        viewer_date             VARCHAR2(14),
        registered_by_me        VARCHAR2(1),
        origin_specialty        VARCHAR2(200),
        id_origin_specialty     NUMBER(24),
        precaution_measures_str table_varchar,
        id_precaution_measures  table_number,
        header_warning          VARCHAR2(1),
        header_warning_str      VARCHAR2(200),
        resolution_date_str     VARCHAR2(200),
        resolution_date         VARCHAR2(200),
        dt_resolved_precision   VARCHAR2(1),
        warning_icon            VARCHAR2(4000),
        review_info             table_varchar,
        id_pat_habit            NUMBER(24),
        flg_area                VARCHAR2(1),
        id_terminology_version  NUMBER(24),
        id_content              VARCHAR2(200 CHAR),
        code_icd                VARCHAR2(200 CHAR),
        term_international_code VARCHAR2(200 CHAR),
        flg_info_button         VARCHAR2(1 CHAR),
        update_time             TIMESTAMP(6) WITH LOCAL TIME ZONE);

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

    /*
        PROCEDURE get_viewer_cfg_vars
        (
            i_lang                IN language.id_language%TYPE,
            i_prof                IN profissional,
            i_id_viewer_checklist IN viewer_checklist.id_viewer_checklist%TYPE,
            o_market              OUT market.id_market%TYPE,
            o_software            OUT software.id_software%TYPE,
            o_profile_template    OUT profile_template.id_profile_template%TYPE,
            o_institution         OUT institution.id_institution%TYPE,
            o_flg_category        OUT category.flg_type%TYPE
        );
    */
    FUNCTION insert_into_config_cat
    (
        i_market            IN NUMBER DEFAULT k_zero_value,
        i_id_config         IN NUMBER DEFAULT NULL,
        i_software          IN NUMBER DEFAULT k_zero_value,
        i_category          IN NUMBER DEFAULT k_zero_value,
        i_config_parent     IN NUMBER DEFAULT NULL,
        i_inst_owner_parent IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_id_vwr_item(i_name IN VARCHAR2) RETURN NUMBER;

    FUNCTION get_icon_color(i_flg_checklist IN VARCHAR2) RETURN VARCHAR2;

    -- ******************************************************************************
    FUNCTION get_icon_name(i_flg_checklist IN VARCHAR2) RETURN VARCHAR2;

    -- ******************************************************************************
    FUNCTION get_icon_tooltip
    (
        i_lang          IN NUMBER,
        i_flg_checklist IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE ins_vwr_checklist_cfg
    (
        i_id_vwr_checklist IN NUMBER,
        i_order_rank       IN NUMBER DEFAULT 0,
        i_flg_default      IN VARCHAR2 DEFAULT 'N',
        i_id_config        IN NUMBER,
        i_id_inst_owner    IN NUMBER
    );

    PROCEDURE set_cfg_checklist;

    PROCEDURE ins_cfg_table
    (
        i_id_checklist   IN NUMBER,
        i_id_item        IN NUMBER,
        i_id_config      IN NUMBER,
        i_flg_scope_type IN VARCHAR2 DEFAULT NULL,
        i_desc_alt       IN VARCHAR2 DEFAULT NULL,
        i_order_rank     IN VARCHAR2,
        i_id_inst_owner  IN NUMBER DEFAULT k_zero_value
    );

    PROCEDURE config_vwr_4_edis_phy;
    PROCEDURE config_vwr_4_edis_nur;
    PROCEDURE config_vwr_4_inp_phy;
    PROCEDURE config_vwr_4_inp_nur;
    PROCEDURE config_vwr_4_outp_phy_nur;
    PROCEDURE config_vwr_4_oris_phy_nur;
    PROCEDURE config_vwr_4_pp_phy_nur;
    PROCEDURE config_vwr_4_care_phy_nur;
    PROCEDURE config_vwr_4_physio_all;
    PROCEDURE config_vwr_4_rt_all;
    PROCEDURE config_vwr_4_pha_all;
    PROCEDURE config_vwr_4_cm_all;
    PROCEDURE config_vwr_4_diet_all;
    PROCEDURE config_vwr_4_social_all;
    PROCEDURE config_vwr_4_triage_all;
    PROCEDURE config_vwr_4_psycho_all;
	
    PROCEDURE reset_and_recreate_cfg;
	
    FUNCTION ins_checklist_item
    (
        i_checklist IN NUMBER,
        i_item      IN NUMBER
    ) RETURN NUMBER;

END pk_viewer_checklist;
/
