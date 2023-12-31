/*-- Last Change Revision: $Rev: 1666928 $*/
/*-- Last Change by: $Author: nuno.alves $*/
/*-- Date of last change: $Date: 2014-12-01 14:42:22 +0000 (seg, 01 dez 2014) $*/
CREATE OR REPLACE PACKAGE ts_pn_area_soft_inst
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Novembro 13, 2014 15:52:25
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PN_AREA_SOFT_INST"
    TYPE pn_area_soft_inst_tc IS TABLE OF pn_area_soft_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pn_area_soft_inst_ntt IS TABLE OF pn_area_soft_inst%ROWTYPE;
    TYPE pn_area_soft_inst_vat IS VARRAY(100) OF pn_area_soft_inst%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pn_area_soft_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pn_area_soft_inst%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pn_area_soft_inst%ROWTYPE;

    -- Column Collection based on column "ID_PN_AREA"
    TYPE id_pn_area_cc IS TABLE OF pn_area_soft_inst.id_pn_area%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF pn_area_soft_inst.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF pn_area_soft_inst.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_DEPARTMENT"
    TYPE id_department_cc IS TABLE OF pn_area_soft_inst.id_department%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_DEP_CLIN_SERV"
    TYPE id_dep_clin_serv_cc IS TABLE OF pn_area_soft_inst.id_dep_clin_serv%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NR_REC_PAGE_SUMMARY"
    TYPE nr_rec_page_summary_cc IS TABLE OF pn_area_soft_inst.nr_rec_page_summary%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DATA_SORT_SUMMARY"
    TYPE data_sort_summary_cc IS TABLE OF pn_area_soft_inst.data_sort_summary%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NR_REC_PAGE_HIST"
    TYPE nr_rec_page_hist_cc IS TABLE OF pn_area_soft_inst.nr_rec_page_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_REPORT_TITLE_TYPE"
    TYPE flg_report_title_type_cc IS TABLE OF pn_area_soft_inst.flg_report_title_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_AVAILABLE"
    TYPE flg_available_cc IS TABLE OF pn_area_soft_inst.flg_available%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF pn_area_soft_inst.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF pn_area_soft_inst.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF pn_area_soft_inst.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF pn_area_soft_inst.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF pn_area_soft_inst.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF pn_area_soft_inst.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "SUMMARY_DEFAULT_FILTER"
    TYPE summary_default_filter_cc IS TABLE OF pn_area_soft_inst.summary_default_filter%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "TIME_TO_CLOSE_NOTE"
    TYPE time_to_close_note_cc IS TABLE OF pn_area_soft_inst.time_to_close_note%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "TIME_TO_START_DOCUM"
    TYPE time_to_start_docum_cc IS TABLE OF pn_area_soft_inst.time_to_start_docum%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_REPORT"
    TYPE id_report_cc IS TABLE OF pn_area_soft_inst.id_report%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_software_in            IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in         IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in             IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in          IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in       IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in    IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT 5,
        data_sort_summary_in      IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT 'DESC',
        nr_rec_page_hist_in       IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT 5,
        flg_report_title_type_in  IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT 'B',
        flg_available_in          IN pn_area_soft_inst.flg_available%TYPE DEFAULT 'Y',
        create_user_in            IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in            IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in            IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        summary_default_filter_in IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT 'N',
        time_to_close_note_in     IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_start_docum_in    IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        id_report_in              IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_software_in            IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in         IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in             IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in          IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in       IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in    IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT 5,
        data_sort_summary_in      IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT 'DESC',
        nr_rec_page_hist_in       IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT 5,
        flg_report_title_type_in  IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT 'B',
        flg_available_in          IN pn_area_soft_inst.flg_available%TYPE DEFAULT 'Y',
        create_user_in            IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in            IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in            IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        summary_default_filter_in IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT 'N',
        time_to_close_note_in     IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_start_docum_in    IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        id_report_in              IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN pn_area_soft_inst%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pn_area_soft_inst%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pn_area_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pn_area_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_software_in             IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in          IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in              IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in           IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in        IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in     IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        nr_rec_page_summary_nin    IN BOOLEAN := TRUE,
        data_sort_summary_in       IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        data_sort_summary_nin      IN BOOLEAN := TRUE,
        nr_rec_page_hist_in        IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        nr_rec_page_hist_nin       IN BOOLEAN := TRUE,
        flg_report_title_type_in   IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_report_title_type_nin  IN BOOLEAN := TRUE,
        flg_available_in           IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin          IN BOOLEAN := TRUE,
        create_user_in             IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        summary_default_filter_in  IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        summary_default_filter_nin IN BOOLEAN := TRUE,
        time_to_close_note_in      IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_close_note_nin     IN BOOLEAN := TRUE,
        time_to_start_docum_in     IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        time_to_start_docum_nin    IN BOOLEAN := TRUE,
        id_report_in               IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        id_report_nin              IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_software_in             IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in          IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in              IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in           IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in        IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in     IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        nr_rec_page_summary_nin    IN BOOLEAN := TRUE,
        data_sort_summary_in       IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        data_sort_summary_nin      IN BOOLEAN := TRUE,
        nr_rec_page_hist_in        IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        nr_rec_page_hist_nin       IN BOOLEAN := TRUE,
        flg_report_title_type_in   IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_report_title_type_nin  IN BOOLEAN := TRUE,
        flg_available_in           IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin          IN BOOLEAN := TRUE,
        create_user_in             IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        summary_default_filter_in  IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        summary_default_filter_nin IN BOOLEAN := TRUE,
        time_to_close_note_in      IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_close_note_nin     IN BOOLEAN := TRUE,
        time_to_start_docum_in     IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        time_to_start_docum_nin    IN BOOLEAN := TRUE,
        id_report_in               IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        id_report_nin              IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        nr_rec_page_summary_in     IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        nr_rec_page_summary_nin    IN BOOLEAN := TRUE,
        data_sort_summary_in       IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        data_sort_summary_nin      IN BOOLEAN := TRUE,
        nr_rec_page_hist_in        IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        nr_rec_page_hist_nin       IN BOOLEAN := TRUE,
        flg_report_title_type_in   IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_report_title_type_nin  IN BOOLEAN := TRUE,
        flg_available_in           IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin          IN BOOLEAN := TRUE,
        create_user_in             IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        summary_default_filter_in  IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        summary_default_filter_nin IN BOOLEAN := TRUE,
        time_to_close_note_in      IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_close_note_nin     IN BOOLEAN := TRUE,
        time_to_start_docum_in     IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        time_to_start_docum_nin    IN BOOLEAN := TRUE,
        id_report_in               IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        id_report_nin              IN BOOLEAN := TRUE,
        where_in                   VARCHAR2,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    PROCEDURE upd
    (
        nr_rec_page_summary_in     IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        nr_rec_page_summary_nin    IN BOOLEAN := TRUE,
        data_sort_summary_in       IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        data_sort_summary_nin      IN BOOLEAN := TRUE,
        nr_rec_page_hist_in        IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        nr_rec_page_hist_nin       IN BOOLEAN := TRUE,
        flg_report_title_type_in   IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_report_title_type_nin  IN BOOLEAN := TRUE,
        flg_available_in           IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        flg_available_nin          IN BOOLEAN := TRUE,
        create_user_in             IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        summary_default_filter_in  IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        summary_default_filter_nin IN BOOLEAN := TRUE,
        time_to_close_note_in      IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_close_note_nin     IN BOOLEAN := TRUE,
        time_to_start_docum_in     IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        time_to_start_docum_nin    IN BOOLEAN := TRUE,
        id_report_in               IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        id_report_nin              IN BOOLEAN := TRUE,
        where_in                   VARCHAR2,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_software_in            IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in         IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in             IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in          IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in       IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in    IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        data_sort_summary_in      IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        nr_rec_page_hist_in       IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        flg_report_title_type_in  IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_available_in          IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        create_user_in            IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in            IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in            IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        summary_default_filter_in IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        time_to_close_note_in     IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_start_docum_in    IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        id_report_in              IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_software_in            IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in         IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in             IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in          IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in       IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        nr_rec_page_summary_in    IN pn_area_soft_inst.nr_rec_page_summary%TYPE DEFAULT NULL,
        data_sort_summary_in      IN pn_area_soft_inst.data_sort_summary%TYPE DEFAULT NULL,
        nr_rec_page_hist_in       IN pn_area_soft_inst.nr_rec_page_hist%TYPE DEFAULT NULL,
        flg_report_title_type_in  IN pn_area_soft_inst.flg_report_title_type%TYPE DEFAULT NULL,
        flg_available_in          IN pn_area_soft_inst.flg_available%TYPE DEFAULT NULL,
        create_user_in            IN pn_area_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in            IN pn_area_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in     IN pn_area_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in            IN pn_area_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in            IN pn_area_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in     IN pn_area_soft_inst.update_institution%TYPE DEFAULT NULL,
        summary_default_filter_in IN pn_area_soft_inst.summary_default_filter%TYPE DEFAULT NULL,
        time_to_close_note_in     IN pn_area_soft_inst.time_to_close_note%TYPE DEFAULT NULL,
        time_to_start_docum_in    IN pn_area_soft_inst.time_to_start_docum%TYPE DEFAULT NULL,
        id_report_in              IN pn_area_soft_inst.id_report%TYPE DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pn_area_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pn_area_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pn_area_soft_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pn_area_soft_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Use Native Dynamic SQL increment a single NUMBER column
    -- for all rows specified by the dynamic WHERE clause
    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2 := NULL,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    PROCEDURE increment_onecol
    (
        colname_in         IN all_tab_columns.column_name%TYPE,
        where_in           IN VARCHAR2 := NULL,
        increment_value_in IN NUMBER DEFAULT 1,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_software_in      IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in   IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in       IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in    IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_software_in      IN pn_area_soft_inst.id_software%TYPE,
        id_institution_in   IN pn_area_soft_inst.id_institution%TYPE,
        id_pn_area_in       IN pn_area_soft_inst.id_pn_area%TYPE,
        id_department_in    IN pn_area_soft_inst.id_department%TYPE,
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for primary key column ID_SOFTWARE
    PROCEDURE del_id_software
    (
        id_software_in  IN pn_area_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_SOFTWARE
    PROCEDURE del_id_software
    (
        id_software_in  IN pn_area_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pn_area_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN pn_area_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PN_AREA
    PROCEDURE del_id_pn_area
    (
        id_pn_area_in   IN pn_area_soft_inst.id_pn_area%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PN_AREA
    PROCEDURE del_id_pn_area
    (
        id_pn_area_in   IN pn_area_soft_inst.id_pn_area%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_DEPARTMENT
    PROCEDURE del_id_department
    (
        id_department_in IN pn_area_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_DEPARTMENT
    PROCEDURE del_id_department
    (
        id_department_in IN pn_area_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for primary key column ID_DEP_CLIN_SERV
    PROCEDURE del_id_dep_clin_serv
    (
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_DEP_CLIN_SERV
    PROCEDURE del_id_dep_clin_serv
    (
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PNASI_DCS_FK foreign key value
    PROCEDURE del_pnasi_dcs_fk
    (
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PNASI_DCS_FK foreign key value
    PROCEDURE del_pnasi_dcs_fk
    (
        id_dep_clin_serv_in IN pn_area_soft_inst.id_dep_clin_serv%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PNASI_INST_FK foreign key value
    PROCEDURE del_pnasi_inst_fk
    (
        id_institution_in IN pn_area_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PNASI_INST_FK foreign key value
    PROCEDURE del_pnasi_inst_fk
    (
        id_institution_in IN pn_area_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PNASI_PNA_FK foreign key value
    PROCEDURE del_pnasi_pna_fk
    (
        id_pn_area_in   IN pn_area_soft_inst.id_pn_area%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PNASI_PNA_FK foreign key value
    PROCEDURE del_pnasi_pna_fk
    (
        id_pn_area_in   IN pn_area_soft_inst.id_pn_area%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PNASI_S_FK foreign key value
    PROCEDURE del_pnasi_s_fk
    (
        id_software_in  IN pn_area_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PNASI_S_FK foreign key value
    PROCEDURE del_pnasi_s_fk
    (
        id_software_in  IN pn_area_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PNTA_DEP_FK foreign key value
    PROCEDURE del_pnta_dep_fk
    (
        id_department_in IN pn_area_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PNTA_DEP_FK foreign key value
    PROCEDURE del_pnta_dep_fk
    (
        id_department_in IN pn_area_soft_inst.id_department%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows specified by dynamic WHERE clause
    PROCEDURE del_by
    (
        where_clause_in IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified VARCHAR2 column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified VARCHAR2 column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN VARCHAR2,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified DATE column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN DATE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified DATE column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN DATE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified TIMESTAMP column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN TIMESTAMP WITH LOCAL TIME ZONE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified TIMESTAMP column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN TIMESTAMP WITH LOCAL TIME ZONE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows where the specified NUMBER column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN NUMBER,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows where the specified NUMBER column has
    -- a value that matches the specfified value.
    PROCEDURE del_by_col
    (
        colname_in      IN VARCHAR2,
        colvalue_in     IN NUMBER,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Initialize a record with default values for columns in the table.
    PROCEDURE initrec(pn_area_soft_inst_inout IN OUT pn_area_soft_inst%ROWTYPE);

    FUNCTION initrec RETURN pn_area_soft_inst%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pn_area_soft_inst_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pn_area_soft_inst_tc;

END ts_pn_area_soft_inst;
/
