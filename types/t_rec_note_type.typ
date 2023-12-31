CREATE OR REPLACE TYPE t_rec_note_type force AS OBJECT
(
    id_pn_area               NUMBER(24),
    id_pn_note_type          NUMBER(24),
    rank                     NUMBER(6),
    max_nr_notes             NUMBER(6),
    max_nr_draft_notes       NUMBER(6),
    max_nr_draft_addendums   NUMBER(6),
    flg_addend_other_prof    VARCHAR2(1 CHAR),
    flg_show_empty_blocks    VARCHAR2(1 CHAR),
    flg_import_available     VARCHAR2(1 CHAR),
    flg_sign_off_login_avail VARCHAR2(1 CHAR),
    flg_last_24h             VARCHAR2(1 CHAR),
    flg_dictation_editable   VARCHAR2(1 CHAR),
    flg_clear_information    VARCHAR2(1 CHAR),
    flg_review_all           VARCHAR2(1 CHAR),
    flg_edit_after_disch     VARCHAR2(1 CHAR),
    flg_import_first         VARCHAR2(1 CHAR),
    flg_write                VARCHAR2(1 CHAR),
    flg_copy_edit_replace    VARCHAR2(1 CHAR),
    gender                   VARCHAR2(2 CHAR),
    age_min                  NUMBER(3),
    age_max                  NUMBER(3),
    flg_expand_sblocks       VARCHAR2(1 CHAR),
    flg_synchronized         VARCHAR2(1 CHAR),
    flg_show_import_menu     VARCHAR2(1 CHAR),
    flg_edit_other_prof      VARCHAR2(1 CHAR),
    flg_create_on_app        VARCHAR2(1 CHAR),
    flg_autopop_warning      VARCHAR2(1 CHAR),
    flg_discharge_warning    VARCHAR2(1 CHAR),
    flg_disch_warning_option VARCHAR2(1 CHAR),
    flg_review_warning       VARCHAR2(1 CHAR),
    flg_review_warn_option   VARCHAR2(1 CHAR),
    flg_import_warning       VARCHAR2(1 CHAR),
    flg_help_save            VARCHAR2(1 CHAR),
    flg_edit_only_last       VARCHAR2(1 CHAR),
    flg_save_only_screen     VARCHAR2(1 CHAR),
    flg_status_available     VARCHAR2(1 CHAR),
    flg_partial_warning      VARCHAR2(1 CHAR),
    flg_remove_on_ok         VARCHAR2(1 CHAR),
    editable_nr_min          NUMBER(24),
    flg_suggest_concept      VARCHAR2(1 CHAR),
    flg_review_on_ok         VARCHAR2(1 CHAR),
    flg_partial_load         VARCHAR2(1 CHAR),
    flg_viewer_type          VARCHAR2(1 CHAR),
    flg_sign_off             VARCHAR2(1 CHAR),
    flg_type                 VARCHAR2(1 CHAR),
    flg_cancel               VARCHAR2(1 CHAR),
    flg_submit               VARCHAR2(1 CHAR),
    cal_delay_time           NUMBER(24),
    cal_icu_delay_time       NUMBER(6),
    flg_cal_time_filter      VARCHAR2(2 CHAR),
    flg_sync_after_disch     VARCHAR2(1 CHAR),
    flg_edit_condition       VARCHAR2(1 CHAR),
    flg_patient_id_warning   VARCHAR2(1 CHAR),
    flg_show_signature       VARCHAR2(1 CHAR),
    flg_show_free_text        VARCHAR2(1 CHAR)
)
;
/
