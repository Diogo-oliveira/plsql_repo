/*-- Last Change Revision: $Rev: 2029144 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:02 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_epis_er_law_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Novembro 2, 2011 9:58:16
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_ER_LAW_HIST"
    TYPE epis_er_law_hist_tc IS TABLE OF epis_er_law_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_er_law_hist_ntt IS TABLE OF epis_er_law_hist%ROWTYPE;
    TYPE epis_er_law_hist_vat IS VARRAY(100) OF epis_er_law_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_er_law_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_er_law_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_er_law_hist%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_ER_LAW"
    TYPE id_epis_er_law_cc IS TABLE OF epis_er_law_hist.id_epis_er_law%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_EPIS_ER_LAW_HIST"
    TYPE dt_epis_er_law_hist_cc IS TABLE OF epis_er_law_hist.dt_epis_er_law_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPISODE"
    TYPE id_episode_cc IS TABLE OF epis_er_law_hist.id_episode%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_ACTIVATION"
    TYPE dt_activation_cc IS TABLE OF epis_er_law_hist.dt_activation%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_INACTIVATION"
    TYPE dt_inactivation_cc IS TABLE OF epis_er_law_hist.dt_inactivation%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_ER_LAW_STATUS"
    TYPE flg_er_law_status_cc IS TABLE OF epis_er_law_hist.flg_er_law_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CANCEL_REASON"
    TYPE id_cancel_reason_cc IS TABLE OF epis_er_law_hist.id_cancel_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES_CANCEL"
    TYPE notes_cancel_cc IS TABLE OF epis_er_law_hist.notes_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_CREATE"
    TYPE id_prof_create_cc IS TABLE OF epis_er_law_hist.id_prof_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CREATE"
    TYPE dt_create_cc IS TABLE OF epis_er_law_hist.dt_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_er_law_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_er_law_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_er_law_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_er_law_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_er_law_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_er_law_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN epis_er_law_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_er_law_hist%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_er_law_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_er_law_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_activation_nin      IN BOOLEAN := TRUE,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        dt_inactivation_nin    IN BOOLEAN := TRUE,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        flg_er_law_status_nin  IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_activation_nin      IN BOOLEAN := TRUE,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        dt_inactivation_nin    IN BOOLEAN := TRUE,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        flg_er_law_status_nin  IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_activation_nin      IN BOOLEAN := TRUE,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        dt_inactivation_nin    IN BOOLEAN := TRUE,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        flg_er_law_status_nin  IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        id_episode_nin         IN BOOLEAN := TRUE,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_activation_nin      IN BOOLEAN := TRUE,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        dt_inactivation_nin    IN BOOLEAN := TRUE,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        flg_er_law_status_nin  IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin       IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        id_episode_in          IN epis_er_law_hist.id_episode%TYPE DEFAULT NULL,
        dt_activation_in       IN epis_er_law_hist.dt_activation%TYPE DEFAULT NULL,
        dt_inactivation_in     IN epis_er_law_hist.dt_inactivation%TYPE DEFAULT NULL,
        flg_er_law_status_in   IN epis_er_law_hist.flg_er_law_status%TYPE DEFAULT NULL,
        id_cancel_reason_in    IN epis_er_law_hist.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in        IN epis_er_law_hist.notes_cancel%TYPE DEFAULT NULL,
        id_prof_create_in      IN epis_er_law_hist.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in           IN epis_er_law_hist.dt_create%TYPE DEFAULT NULL,
        create_user_in         IN epis_er_law_hist.create_user%TYPE DEFAULT NULL,
        create_time_in         IN epis_er_law_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN epis_er_law_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN epis_er_law_hist.update_user%TYPE DEFAULT NULL,
        update_time_in         IN epis_er_law_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN epis_er_law_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_er_law_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_er_law_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_er_law_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_er_law_hist_tc,
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
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_er_law_in      IN epis_er_law_hist.id_epis_er_law%TYPE,
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_ER_LAW
    PROCEDURE del_id_epis_er_law
    (
        id_epis_er_law_in IN epis_er_law_hist.id_epis_er_law%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_ER_LAW
    PROCEDURE del_id_epis_er_law
    (
        id_epis_er_law_in IN epis_er_law_hist.id_epis_er_law%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column DT_EPIS_ER_LAW_HIST
    PROCEDURE del_dt_epis_er_law_hist
    (
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column DT_EPIS_ER_LAW_HIST
    PROCEDURE del_dt_epis_er_law_hist
    (
        dt_epis_er_law_hist_in IN epis_er_law_hist.dt_epis_er_law_hist%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this ERLWH_CNC_RS_FK foreign key value
    PROCEDURE del_erlwh_cnc_rs_fk
    (
        id_cancel_reason_in IN epis_er_law_hist.id_cancel_reason%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ERLWH_CNC_RS_FK foreign key value
    PROCEDURE del_erlwh_cnc_rs_fk
    (
        id_cancel_reason_in IN epis_er_law_hist.id_cancel_reason%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this ERLWH_EPIS_FK foreign key value
    PROCEDURE del_erlwh_epis_fk
    (
        id_episode_in   IN epis_er_law_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ERLWH_EPIS_FK foreign key value
    PROCEDURE del_erlwh_epis_fk
    (
        id_episode_in   IN epis_er_law_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this ERLWH_ERLW_FK foreign key value
    PROCEDURE del_erlwh_erlw_fk
    (
        id_episode_in   IN epis_er_law_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ERLWH_ERLW_FK foreign key value
    PROCEDURE del_erlwh_erlw_fk
    (
        id_episode_in   IN epis_er_law_hist.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
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
    PROCEDURE initrec(epis_er_law_hist_inout IN OUT epis_er_law_hist%ROWTYPE);

    FUNCTION initrec RETURN epis_er_law_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_er_law_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_er_law_hist_tc;

END ts_epis_er_law_hist;
/
