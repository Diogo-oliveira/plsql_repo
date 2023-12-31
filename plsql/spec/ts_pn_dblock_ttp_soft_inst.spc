/*-- Last Change Revision: $Rev: 1865206 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2018-09-12 15:10:49 +0100 (qua, 12 set 2018) $*/
CREATE OR REPLACE PACKAGE ts_pn_dblock_ttp_soft_inst
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2018-09-12 15:02:49
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on pn_dblock_ttp_soft_inst
    TYPE pn_dblock_ttp_soft_inst_tc IS TABLE OF pn_dblock_ttp_soft_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pn_dblock_ttp_soft_inst_ntt IS TABLE OF pn_dblock_ttp_soft_inst%ROWTYPE;
    TYPE pn_dblock_ttp_soft_inst_vat IS VARRAY(100) OF pn_dblock_ttp_soft_inst%ROWTYPE;

    -- Column Collection based on column ID_PN_SOAP_BLOCK
    TYPE id_pn_soap_block_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEPARTMENT
    TYPE id_department_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_department%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_INSTITUTION
    TYPE id_institution_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DEP_CLIN_SERV
    TYPE id_dep_clin_serv_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PN_NOTE_TYPE
    TYPE id_pn_note_type_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_TASK_TYPE
    TYPE id_task_type_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_task_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PN_DATA_BLOCK
    TYPE id_pn_data_block_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_SOFTWARE
    TYPE id_software_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_AUTO_POPULATED
    TYPE flg_auto_populated_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF pn_dblock_ttp_soft_inst.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF pn_dblock_ttp_soft_inst.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF pn_dblock_ttp_soft_inst.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF pn_dblock_ttp_soft_inst.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF pn_dblock_ttp_soft_inst.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF pn_dblock_ttp_soft_inst.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_AVAILABLE
    TYPE flg_available_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_available%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_SELECTED
    TYPE flg_selected_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_selected%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_IMPORT_FILTER
    TYPE flg_import_filter_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_import_filter%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column LAST_N_RECORDS_NR
    TYPE last_n_records_nr_cc IS TABLE OF pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_SHORTCUT_FILTER
    TYPE flg_shortcut_filter_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_SYNCHRONIZED
    TYPE flg_synchronized_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_synchronized%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column REVIEW_CAT
    TYPE review_cat_cc IS TABLE OF pn_dblock_ttp_soft_inst.review_cat%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_REVIEW_AVAIL
    TYPE flg_review_avail_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_review_avail%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_DESCRIPTION
    TYPE flg_description_cc IS TABLE OF pn_dblock_ttp_soft_inst.flg_description%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column DESCRIPTION_CONDITION
TYPE DESCRIPTION_CONDITION_CC IS TABLE OF pn_dblock_ttp_soft_inst.DESCRIPTION_CONDITION%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column FLG_DT_TASK
TYPE FLG_DT_TASK_CC IS TABLE OF pn_dblock_ttp_soft_inst.FLG_DT_TASK%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_TASK_RELATED
    TYPE id_task_related_cc IS TABLE OF pn_dblock_ttp_soft_inst.id_task_related%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_pn_soap_block_in    IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in       IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in      IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in    IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in     IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in        IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in    IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in         IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in  IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT 'N',
        create_user_in         IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        flg_available_in       IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT 'Y',
        flg_selected_in        IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT 'N',
        flg_import_filter_in   IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT 'N',
        last_n_records_nr_in   IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        flg_shortcut_filter_in IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT 'N',
        flg_synchronized_in    IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT 'N',
        review_cat_in          IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        flg_review_avail_in    IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT 'N',
        flg_description_in     IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
        id_task_related_in       IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_pn_soap_block_in    IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in       IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in      IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in    IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in     IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in        IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in    IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in         IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in  IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT 'N',
        create_user_in         IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        flg_available_in       IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT 'Y',
        flg_selected_in        IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT 'N',
        flg_import_filter_in   IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT 'N',
        last_n_records_nr_in   IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        flg_shortcut_filter_in IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT 'N',
        flg_synchronized_in    IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT 'N',
        review_cat_in          IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        flg_review_avail_in    IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT 'N',
        flg_description_in     IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
        id_task_related_in       IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN pn_dblock_ttp_soft_inst%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN pn_dblock_ttp_soft_inst%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN pn_dblock_ttp_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN pn_dblock_ttp_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_pn_soap_block_in     IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in        IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in       IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in     IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in      IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in         IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in     IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in          IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in   IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        flg_auto_populated_nin  IN BOOLEAN := TRUE,
        create_user_in          IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_available_in        IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        flg_selected_in         IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_selected_nin        IN BOOLEAN := TRUE,
        flg_import_filter_in    IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        flg_import_filter_nin   IN BOOLEAN := TRUE,
        last_n_records_nr_in    IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        last_n_records_nr_nin   IN BOOLEAN := TRUE,
        flg_shortcut_filter_in  IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_shortcut_filter_nin IN BOOLEAN := TRUE,
        flg_synchronized_in     IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        flg_synchronized_nin    IN BOOLEAN := TRUE,
        review_cat_in           IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        review_cat_nin          IN BOOLEAN := TRUE,
        flg_review_avail_in     IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_review_avail_nin    IN BOOLEAN := TRUE,
        flg_description_in      IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
        flg_description_nin     IN BOOLEAN := TRUE,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_nin IN BOOLEAN := TRUE,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
FLG_DT_TASK_nin IN BOOLEAN := TRUE,
        id_task_related_in        IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        id_task_related_nin       IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_pn_soap_block_in     IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in        IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in       IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in     IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in      IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in         IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in     IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in          IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in   IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        flg_auto_populated_nin  IN BOOLEAN := TRUE,
        create_user_in          IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_available_in        IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        flg_selected_in         IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_selected_nin        IN BOOLEAN := TRUE,
        flg_import_filter_in    IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        flg_import_filter_nin   IN BOOLEAN := TRUE,
        last_n_records_nr_in    IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        last_n_records_nr_nin   IN BOOLEAN := TRUE,
        flg_shortcut_filter_in  IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_shortcut_filter_nin IN BOOLEAN := TRUE,
        flg_synchronized_in     IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        flg_synchronized_nin    IN BOOLEAN := TRUE,
        review_cat_in           IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        review_cat_nin          IN BOOLEAN := TRUE,
        flg_review_avail_in     IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_review_avail_nin    IN BOOLEAN := TRUE,
        flg_description_in      IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
        flg_description_nin     IN BOOLEAN := TRUE,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_nin IN BOOLEAN := TRUE,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
FLG_DT_TASK_nin IN BOOLEAN := TRUE,
        id_task_related_in        IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        id_task_related_nin       IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        flg_auto_populated_in   IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        flg_auto_populated_nin  IN BOOLEAN := TRUE,
        create_user_in          IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_available_in        IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        flg_selected_in         IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_selected_nin        IN BOOLEAN := TRUE,
        flg_import_filter_in    IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        flg_import_filter_nin   IN BOOLEAN := TRUE,
        last_n_records_nr_in    IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        last_n_records_nr_nin   IN BOOLEAN := TRUE,
        flg_shortcut_filter_in  IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_shortcut_filter_nin IN BOOLEAN := TRUE,
        flg_synchronized_in     IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        flg_synchronized_nin    IN BOOLEAN := TRUE,
        review_cat_in           IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        review_cat_nin          IN BOOLEAN := TRUE,
        flg_review_avail_in     IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_review_avail_nin    IN BOOLEAN := TRUE,
        flg_description_in      IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
        flg_description_nin     IN BOOLEAN := TRUE,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_nin IN BOOLEAN := TRUE,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
FLG_DT_TASK_nin IN BOOLEAN := TRUE,
        id_task_related_in        IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        id_task_related_nin       IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        flg_auto_populated_in   IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        flg_auto_populated_nin  IN BOOLEAN := TRUE,
        create_user_in          IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_available_in        IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin       IN BOOLEAN := TRUE,
        flg_selected_in         IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_selected_nin        IN BOOLEAN := TRUE,
        flg_import_filter_in    IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        flg_import_filter_nin   IN BOOLEAN := TRUE,
        last_n_records_nr_in    IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        last_n_records_nr_nin   IN BOOLEAN := TRUE,
        flg_shortcut_filter_in  IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_shortcut_filter_nin IN BOOLEAN := TRUE,
        flg_synchronized_in     IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        flg_synchronized_nin    IN BOOLEAN := TRUE,
        review_cat_in           IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        review_cat_nin          IN BOOLEAN := TRUE,
        flg_review_avail_in     IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_review_avail_nin    IN BOOLEAN := TRUE,
        flg_description_in      IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
        flg_description_nin     IN BOOLEAN := TRUE,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_nin IN BOOLEAN := TRUE,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
FLG_DT_TASK_nin IN BOOLEAN := TRUE,
        id_task_related_in        IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        id_task_related_nin       IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_pn_soap_block_in    IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in       IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in      IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in    IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in     IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in        IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in    IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in         IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in  IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        create_user_in         IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        flg_available_in       IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_selected_in        IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_import_filter_in   IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        last_n_records_nr_in   IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        flg_shortcut_filter_in IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_synchronized_in    IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        review_cat_in          IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        flg_review_avail_in    IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_description_in     IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
        id_task_related_in       IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_pn_soap_block_in    IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in       IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in      IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in    IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in     IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in        IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in    IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in         IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        flg_auto_populated_in  IN pn_dblock_ttp_soft_inst.flg_auto_populated%TYPE DEFAULT NULL,
        create_user_in         IN pn_dblock_ttp_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN pn_dblock_ttp_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN pn_dblock_ttp_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN pn_dblock_ttp_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN pn_dblock_ttp_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN pn_dblock_ttp_soft_inst.update_institution%TYPE DEFAULT NULL,
        flg_available_in       IN pn_dblock_ttp_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_selected_in        IN pn_dblock_ttp_soft_inst.flg_selected%TYPE DEFAULT NULL,
        flg_import_filter_in   IN pn_dblock_ttp_soft_inst.flg_import_filter%TYPE DEFAULT NULL,
        last_n_records_nr_in   IN pn_dblock_ttp_soft_inst.last_n_records_nr%TYPE DEFAULT NULL,
        flg_shortcut_filter_in IN pn_dblock_ttp_soft_inst.flg_shortcut_filter%TYPE DEFAULT NULL,
        flg_synchronized_in    IN pn_dblock_ttp_soft_inst.flg_synchronized%TYPE DEFAULT NULL,
        review_cat_in          IN pn_dblock_ttp_soft_inst.review_cat%TYPE DEFAULT NULL,
        flg_review_avail_in    IN pn_dblock_ttp_soft_inst.flg_review_avail%TYPE DEFAULT NULL,
        flg_description_in     IN pn_dblock_ttp_soft_inst.flg_description%TYPE DEFAULT NULL,
DESCRIPTION_CONDITION_in IN PN_DBLOCK_TTP_SOFT_INST.DESCRIPTION_CONDITION%TYPE DEFAULT NULL,
FLG_DT_TASK_in IN PN_DBLOCK_TTP_SOFT_INST.FLG_DT_TASK%TYPE DEFAULT NULL,
        id_task_related_in       IN pn_dblock_ttp_soft_inst.id_task_related%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN pn_dblock_ttp_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN pn_dblock_ttp_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN pn_dblock_ttp_soft_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN pn_dblock_ttp_soft_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Use Native Dynamic SQL increment a single NUMBER column
    -- for all rows specified by the dynamic WHERE clause
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    --increment column value
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pn_soap_block_in IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in    IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in   IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in  IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in     IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in      IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pn_soap_block_in IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        id_department_in    IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        id_institution_in   IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        id_dep_clin_serv_in IN pn_dblock_ttp_soft_inst.id_dep_clin_serv%TYPE,
        id_pn_note_type_in  IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        id_task_type_in     IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        id_pn_data_block_in IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        id_software_in      IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSINT_FK foreign key value
    PROCEDURE del_pdbttsint_fk
    (
        id_pn_note_type_in IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_DB_FK foreign key value
    PROCEDURE del_pdbttsi_db_fk
    (
        id_pn_data_block_in IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_DEP_FK foreign key value
    PROCEDURE del_pdbttsi_dep_fk
    (
        id_department_in IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_MRK_FK foreign key value
    PROCEDURE del_pdbttsi_mrk_fk
    (
        id_institution_in IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_SB_FK foreign key value
    PROCEDURE del_pdbttsi_sb_fk
    (
        id_pn_soap_block_in IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_S_FK foreign key value
    PROCEDURE del_pdbttsi_s_fk
    (
        id_software_in  IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PDBTTSI_TT_FK foreign key value
    PROCEDURE del_pdbttsi_tt_fk
    (
        id_task_type_in IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PDBTTSINT_FK foreign key value
    PROCEDURE del_pdbttsint_fk
    (
        id_pn_note_type_in IN pn_dblock_ttp_soft_inst.id_pn_note_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_DB_FK foreign key value
    PROCEDURE del_pdbttsi_db_fk
    (
        id_pn_data_block_in IN pn_dblock_ttp_soft_inst.id_pn_data_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_DEP_FK foreign key value
    PROCEDURE del_pdbttsi_dep_fk
    (
        id_department_in IN pn_dblock_ttp_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_MRK_FK foreign key value
    PROCEDURE del_pdbttsi_mrk_fk
    (
        id_institution_in IN pn_dblock_ttp_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_SB_FK foreign key value
    PROCEDURE del_pdbttsi_sb_fk
    (
        id_pn_soap_block_in IN pn_dblock_ttp_soft_inst.id_pn_soap_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_S_FK foreign key value
    PROCEDURE del_pdbttsi_s_fk
    (
        id_software_in  IN pn_dblock_ttp_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PDBTTSI_TT_FK foreign key value
    PROCEDURE del_pdbttsi_tt_fk
    (
        id_task_type_in IN pn_dblock_ttp_soft_inst.id_task_type%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(pn_dblock_ttp_soft_inst_inout IN OUT pn_dblock_ttp_soft_inst%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN pn_dblock_ttp_soft_inst%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pn_dblock_ttp_soft_inst_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pn_dblock_ttp_soft_inst_tc;

END ts_pn_dblock_ttp_soft_inst;
/
