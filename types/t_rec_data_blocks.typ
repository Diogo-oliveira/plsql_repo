-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 11/10/2016
-- CHANGE REASON: CALERT-174
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_coll_data_blocks';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_data_blocks AS OBJECT
(
    block_id         NUMBER(24),
    id_pn_data_block NUMBER(24),
    id_pndb_parent   NUMBER(24),
    data_area        VARCHAR2(100 CHAR),
    id_doc_area      NUMBER(24),
    area_name        VARCHAR2(1000 CHAR),
    flg_type         VARCHAR2(2 CHAR),
    flg_import       VARCHAR2(2 CHAR),
    area_level       NUMBER(3),
    flg_scope        VARCHAR2(1 CHAR),

    flg_selected             VARCHAR2(24 CHAR), -- Indicate if the item is selected by default in the import screen.
    flg_actions_available    VARCHAR2(1 CHAR), -- Indicate if the actions button should be available in the edition screen
    id_swf_file_viewer       NUMBER(24), -- Viewer screen that is loaded when the area is selected
    flg_line_on_boxes        VARCHAR2(1 CHAR), -- Indicates if the data block box has a visible line
    gender                   VARCHAR2(2 CHAR), -- Gender in which the note type should be shown (M/F)
    age_min                  NUMBER(3), -- Minimal age in which the note type should be shown
    age_max                  NUMBER(3), -- Maximum age in which the note type should be shown
    flg_pregnant             VARCHAR2(1 CHAR), -- Indicates if the area should be available in pregnant patients
    flg_auto_populated       VARCHAR2(200 CHAR), -- Y-This area should be auto-populated. N-otherwise.
    flg_cp_no_changes_import VARCHAR2(1 CHAR), -- Y-Should be performed a copy and edit action when importing. N-otherwise.
    rank                     NUMBER(6),
    id_pn_task_type          NUMBER(24),
    flg_import_date          VARCHAR2(1 CHAR), -- Y-Should be imported the date when importing a record. N-otherwise.
    flg_outside_period       VARCHAR2(1 CHAR), -- At least the nearest entry interval, defined in Data Block if he does not have values (Y/N)
    days_available_period    NUMBER(6), -- Period of time in days during which a record is available on the Data Block import screen
    id_pn_task_type_prt      NUMBER(24), --Task type parent
    review_context           VARCHAR2(3 CHAR), --context of the review. If the task requires review
    flg_group_on_import      VARCHAR2(1 CHAR),
    id_parent_no_struct      NUMBER(24),
    flg_has_struct_levels    VARCHAR2(1 CHAR),
    flg_last_struct_level    VARCHAR2(1 CHAR),
    count_child              NUMBER,
    flg_show_sub_title       VARCHAR(1 CHAR), -- Y-Shows subtitle (shows doc_area name for templates). N-otherwise
    flg_synchronized         VARCHAR2(200 CHAR), -- Y - If Data Blocks info is to be synchronized with the directed areas, other than templates. N- otherwise
    flg_data_removable       VARCHAR2(3 CHAR), --It is possible to remove the: I-Imported data; P-auto-populated records that does not need review (black ones); N-not applicable. Include all the letters in the flag that aggregate the set of elements that must have the option ''Remove''. This config does not appy to the suggested records (red ones), that can always be removed
    auto_pop_exec_prof_cat   VARCHAR2(200 CHAR), --Professional categories types that executed the task to consider when auto-populating records (join in this column all the needed categories). Null-consider all the professional categories.
    id_summary_page          NUMBER(24), --Identifier of Summary page for scenarios where we dont have the id_doc_area (ex: Assessment Tools)
    flg_focus                VARCHAR2(1 CHAR), -- Y - Indicates this data block has focus in the note when creating a new one. N - Otherwise
    flg_editable             VARCHAR2(1 CHAR), -- Y - Allows the edition of a data block. N - otherwise is disable
    flg_import_filter        VARCHAR2(200 CHAR),
    flg_ea                   VARCHAR2(1 CHAR),
    last_n_records_nr        NUMBER(24),
    flg_group_select_filter  VARCHAR2(24 CHAR),
    flg_synch_area           VARCHAR2(1 CHAR),
    flg_shortcut_filter      VARCHAR2(200 CHAR),
    review_cat               VARCHAR2(200 CHAR),
    flg_review_avail         VARCHAR2(1char),
    flg_description          VARCHAR2(24 CHAR),
    description_condition    VARCHAR2(1000 CHAR),
    id_mtos_score NUMBER(24),
    flg_dt_task              VARCHAR2(200 CHAR) ,
    flg_exc_sum_page_da  VARCHAR2(1 CHAR),
    flg_group_type VARCHAR2(1 CHAR)
)';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_data_blocks AS table of t_rec_data_blocks';
END;
/
--CHANGE END: Pedro Teixeira
