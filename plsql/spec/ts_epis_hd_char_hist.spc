/*-- Last Change Revision: $Rev: 2029149 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:04 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_epis_hd_char_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Junho 15, 2011 10:4:30
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_HD_CHAR_HIST"
    TYPE epis_hd_char_hist_tc IS TABLE OF epis_hd_char_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_hd_char_hist_ntt IS TABLE OF epis_hd_char_hist%ROWTYPE;
    TYPE epis_hd_char_hist_vat IS VARRAY(100) OF epis_hd_char_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_hd_char_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_hd_char_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_hd_char_hist%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_HIDRICS_DET"
    TYPE id_epis_hidrics_det_cc IS TABLE OF epis_hd_char_hist.id_epis_hidrics_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_HIDRICS_CHARACT"
    TYPE id_hidrics_charact_cc IS TABLE OF epis_hd_char_hist.id_hidrics_charact%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_EPIS_HD_CHAR_HIST"
    TYPE dt_epis_hd_char_hist_cc IS TABLE OF epis_hd_char_hist.dt_epis_hd_char_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_hd_char_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_hd_char_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_hd_char_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_hd_char_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_hd_char_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_hd_char_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_LAST_CHANGE"
    TYPE id_prof_last_change_cc IS TABLE OF epis_hd_char_hist.id_prof_last_change%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_EH_DET_CHARACT"
    TYPE dt_eh_det_charact_cc IS TABLE OF epis_hd_char_hist.dt_eh_det_charact%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPIS_HID_FTXT_CHAR"
    TYPE id_epis_hid_ftxt_char_cc IS TABLE OF epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_hidrics_det_in   IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in    IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in  IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in           IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_change_in   IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        dt_eh_det_charact_in     IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_in IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_hidrics_det_in   IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in    IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in  IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in           IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_change_in   IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        dt_eh_det_charact_in     IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_in IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN epis_hd_char_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_hd_char_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_hd_char_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_hd_char_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_hidrics_det_in    IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in     IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in   IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in            IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_prof_last_change_in    IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        id_prof_last_change_nin   IN BOOLEAN := TRUE,
        dt_eh_det_charact_in      IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        dt_eh_det_charact_nin     IN BOOLEAN := TRUE,
        id_epis_hid_ftxt_char_in  IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_nin IN BOOLEAN := TRUE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_hidrics_det_in    IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in     IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in   IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in            IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_prof_last_change_in    IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        id_prof_last_change_nin   IN BOOLEAN := TRUE,
        dt_eh_det_charact_in      IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        dt_eh_det_charact_nin     IN BOOLEAN := TRUE,
        id_epis_hid_ftxt_char_in  IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_nin IN BOOLEAN := TRUE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        create_user_in            IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_prof_last_change_in    IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        id_prof_last_change_nin   IN BOOLEAN := TRUE,
        dt_eh_det_charact_in      IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        dt_eh_det_charact_nin     IN BOOLEAN := TRUE,
        id_epis_hid_ftxt_char_in  IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_nin IN BOOLEAN := TRUE,
        where_in                  VARCHAR2 DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  IN OUT table_varchar
    );

    PROCEDURE upd
    (
        create_user_in            IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin           IN BOOLEAN := TRUE,
        create_time_in            IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin           IN BOOLEAN := TRUE,
        create_institution_in     IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin    IN BOOLEAN := TRUE,
        update_user_in            IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin           IN BOOLEAN := TRUE,
        update_time_in            IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin           IN BOOLEAN := TRUE,
        update_institution_in     IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin    IN BOOLEAN := TRUE,
        id_prof_last_change_in    IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        id_prof_last_change_nin   IN BOOLEAN := TRUE,
        dt_eh_det_charact_in      IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        dt_eh_det_charact_nin     IN BOOLEAN := TRUE,
        id_epis_hid_ftxt_char_in  IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_nin IN BOOLEAN := TRUE,
        where_in                  VARCHAR2 DEFAULT NULL,
        handle_error_in           IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_hidrics_det_in   IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in    IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in  IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in           IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_change_in   IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        dt_eh_det_charact_in     IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_in IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_hidrics_det_in   IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in    IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in  IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        create_user_in           IN epis_hd_char_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_hd_char_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_hd_char_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_hd_char_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_hd_char_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_hd_char_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_change_in   IN epis_hd_char_hist.id_prof_last_change%TYPE DEFAULT NULL,
        dt_eh_det_charact_in     IN epis_hd_char_hist.dt_eh_det_charact%TYPE DEFAULT NULL,
        id_epis_hid_ftxt_char_in IN epis_hd_char_hist.id_epis_hid_ftxt_char%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_hd_char_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_hd_char_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_hd_char_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_hd_char_hist_tc,
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
        id_epis_hidrics_det_in  IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in   IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_hidrics_det_in  IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        id_hidrics_charact_in   IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        dt_epis_hd_char_hist_in IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_HIDRICS_DET
    PROCEDURE del_id_epis_hidrics_det
    (
        id_epis_hidrics_det_in IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_HIDRICS_DET
    PROCEDURE del_id_epis_hidrics_det
    (
        id_epis_hidrics_det_in IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for primary key column ID_HIDRICS_CHARACT
    PROCEDURE del_id_hidrics_charact
    (
        id_hidrics_charact_in IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_HIDRICS_CHARACT
    PROCEDURE del_id_hidrics_charact
    (
        id_hidrics_charact_in IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column DT_EPIS_HD_CHAR_HIST
    PROCEDURE del_dt_epis_hd_char_hist
    (
        dt_epis_hd_char_hist_in IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column DT_EPIS_HD_CHAR_HIST
    PROCEDURE del_dt_epis_hd_char_hist
    (
        dt_epis_hd_char_hist_in IN epis_hd_char_hist.dt_epis_hd_char_hist%TYPE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                OUT table_varchar
    );

    -- Delete all rows for this EHDCH_EPHD_FK foreign key value
    PROCEDURE del_ehdch_ephd_fk
    (
        id_epis_hidrics_det_in IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EHDCH_EPHD_FK foreign key value
    PROCEDURE del_ehdch_ephd_fk
    (
        id_epis_hidrics_det_in IN epis_hd_char_hist.id_epis_hidrics_det%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this EHDCH_HC_FK foreign key value
    PROCEDURE del_ehdch_hc_fk
    (
        id_hidrics_charact_in IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EHDCH_HC_FK foreign key value
    PROCEDURE del_ehdch_hc_fk
    (
        id_hidrics_charact_in IN epis_hd_char_hist.id_hidrics_charact%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this EHDCH_PROF_FK foreign key value
    PROCEDURE del_ehdch_prof_fk
    (
        id_prof_last_change_in IN epis_hd_char_hist.id_prof_last_change%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EHDCH_PROF_FK foreign key value
    PROCEDURE del_ehdch_prof_fk
    (
        id_prof_last_change_in IN epis_hd_char_hist.id_prof_last_change%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
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
    PROCEDURE initrec(epis_hd_char_hist_inout IN OUT epis_hd_char_hist%ROWTYPE);

    FUNCTION initrec RETURN epis_hd_char_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_hd_char_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_hd_char_hist_tc;

END ts_epis_hd_char_hist;
/