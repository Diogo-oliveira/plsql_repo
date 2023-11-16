-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/01/2015 10:27
-- CHANGE REASON: [ALERT-306656] 
CREATE OR REPLACE TYPE t_rec_dblock FORCE AS OBJECT
(
    id_pn_soap_block         NUMBER(24), -- soap block identifier
    id_pn_data_block         NUMBER(24), -- data blzock identifier
    flg_type                 VARCHAR2(2 CHAR), -- data block type flag
    data_area                VARCHAR2(24 CHAR), -- data block internal area
    id_doc_area              NUMBER(24), -- documentation area identifier
    code_pn_data_block       VARCHAR2(200 CHAR), -- data block code for translation
    id_department            NUMBER(24), -- service identifier
    id_dep_clin_serv         NUMBER(24), -- service and specialty association identifier
    flg_import               VARCHAR2(1 CHAR), -- data block importability: (N)ot importable, (T)ext importable, (B)lock importable
    flg_select               VARCHAR2(1 CHAR), -- is data block selectable? Y/N
    flg_scope                VARCHAR2(1 CHAR), -- data block scope: (P)atient, (V)isit, (E)pisode
    dblock_count             NUMBER(6), -- number of data block per soap block
    flg_actions_available    VARCHAR2(1 CHAR), -- Indicate if the actions button should be available in the edition screen
    id_swf_file_viewer       NUMBER(24), -- Viewer screen that is loaded when the area is selected
    flg_line_on_boxes        VARCHAR2(1 CHAR), -- Indicates if the data block box has a visible line
    gender                   VARCHAR2(2 CHAR), -- Gender in which the note type should be shown (M/F)
    age_min                  NUMBER(3), -- Minimal age in which the note type should be shown
    age_max                  NUMBER(3), -- Maximum age in which the note type should be shown
    flg_pregnant             VARCHAR2(1 CHAR), -- Indicates if the area should be available in pregnant patients
    flg_outside_period       VARCHAR2(1 CHAR), -- At least the nearest entry interval, defined in Data Block if he does not have values (Y/N)
    days_available_period    NUMBER(6), -- Period of time in days during which a record is available on the Data Block import screen
    flg_mandatory            VARCHAR2(1 CHAR), -- It's mandatory to fill the Data Block Or not (Y/N)
    flg_cp_no_changes_import VARCHAR2(1 CHAR), -- Y-Should be performed a copy and edit action when importing. N-otherwise.
    flg_import_date          VARCHAR2(1 CHAR), -- Y-Should be imported the date when importing a record. N-otherwise.
    id_sys_button_viewer     NUMBER(24), -- Viewer sys_button where the screen should open
    flg_group_on_import      VARCHAR2(1 CHAR),
    rank                     NUMBER(6),
    flg_wf_viewer            VARCHAR2(3 CHAR),
    id_pndb_parent           NUMBER(24),
    flg_struct_type          VARCHAR2(1 CHAR),
    flg_show_title           VARCHAR2(1 CHAR), -- Indicate if the data block title should appear in the application
    flg_show_sub_title       VARCHAR2(1 CHAR), -- Y - Indicates the data block subtitle should appear in the application (example for assessment tools the subitile is the doc_area). N - Otherwise.
    flg_data_removable       VARCHAR2(3 CHAR), -- I - the remove option is available for the imported records. P-remove options is available for auto-populated records
    auto_pop_exec_prof_cat   VARCHAR2(200 CHAR), --Professional categories types that executed the task to consider when auto-populating records (join in this column all the needed categories). Null-consider all the professional categories.
    id_summary_page          NUMBER(24), --Identifier of Summary page for scenarios where we dont have the id_doc_area (ex: Assessment Tools)
    flg_focus                VARCHAR2(1 CHAR), -- Y - Indicates this data block has focus in the note when creating a new one. N - Otherwise
    flg_editable             VARCHAR2(1 CHAR), -- Y - Allows the edition of a data block. N - otherwise is disable
    flg_group_select_filter  VARCHAR2(24 CHAR),
    id_task_type_ftxt        NUMBER(24),
    flg_order_type           VARCHAR2(1 CHAR),
    flg_signature            VARCHAR2(1 CHAR),
    flg_min_value            VARCHAR2(24 CHAR),
    flg_default_value        VARCHAR2(24 CHAR),
    flg_max_value            VARCHAR2(24 CHAR),
    flg_format               VARCHAR2(24 CHAR),
    flg_validation           VARCHAR2(24 CHAR),
    id_pndb_related          NUMBER(24), -- indicates the datablock related that should be populated when this is populated (when TASK_TIMELINE_EA.ID_TASK_RELATED has the same ID for diferent tasks)
    value_viewer             VARCHAR2(200 CHAR),
    file_name                VARCHAR2(200 CHAR),
    file_extension           VARCHAR2(3 CHAR),
    id_mtos_score            NUMBER(24),
    min_days_period          NUMBER(12, 6),
    max_days_period          NUMBER(12, 6),
    default_days_period      NUMBER(12, 6),
    flg_exc_sum_page_da      VARCHAR2(1 CHAR),
    flg_group_type           VARCHAR2(1 CHAR),
    desc_function            VARCHAR2(200 CHAR),
    CONSTRUCTOR FUNCTION t_rec_dblock RETURN SELF AS RESULT
)
;
-- CHANGE END: Paulo Teixeira
/
