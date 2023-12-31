/*-- Last Change Revision: $Rev: 2029353 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_rehab_presc_change
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Agosto 25, 2010 8:34:8
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "REHAB_PRESC_CHANGE"
    TYPE rehab_presc_change_tc IS TABLE OF rehab_presc_change%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE rehab_presc_change_ntt IS TABLE OF rehab_presc_change%ROWTYPE;
    TYPE rehab_presc_change_vat IS VARRAY(100) OF rehab_presc_change%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF rehab_presc_change%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF rehab_presc_change%ROWTYPE;
    TYPE vat IS VARRAY(100) OF rehab_presc_change%ROWTYPE;

    -- Column Collection based on column "ID_REHAB_PRESC"
    TYPE id_rehab_presc_cc IS TABLE OF rehab_presc_change.id_rehab_presc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CHANGE"
    TYPE id_change_cc IS TABLE OF rehab_presc_change.id_change%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CHANGE"
    TYPE dt_change_cc IS TABLE OF rehab_presc_change.dt_change%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF rehab_presc_change.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "EXEC_PER_SESSION"
    TYPE exec_per_session_cc IS TABLE OF rehab_presc_change.exec_per_session%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EXEC_INSTITUTION"
    TYPE id_exec_institution_cc IS TABLE OF rehab_presc_change.id_exec_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF rehab_presc_change.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS_CHANGE"
    TYPE flg_status_change_cc IS TABLE OF rehab_presc_change.flg_status_change%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_REQ"
    TYPE id_prof_req_cc IS TABLE OF rehab_presc_change.id_prof_req%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_REQ"
    TYPE dt_req_cc IS TABLE OF rehab_presc_change.dt_req%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_ACCEPT"
    TYPE id_prof_accept_cc IS TABLE OF rehab_presc_change.id_prof_accept%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_ACCEPT"
    TYPE dt_accept_cc IS TABLE OF rehab_presc_change.dt_accept%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_DECLINE"
    TYPE id_prof_decline_cc IS TABLE OF rehab_presc_change.id_prof_decline%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_DECLINE"
    TYPE dt_decline_cc IS TABLE OF rehab_presc_change.dt_decline%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES_DECLINE"
    TYPE notes_decline_cc IS TABLE OF rehab_presc_change.notes_decline%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF rehab_presc_change.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF rehab_presc_change.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF rehab_presc_change.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF rehab_presc_change.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF rehab_presc_change.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF rehab_presc_change.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES_CHANGE"
    TYPE notes_change_cc IS TABLE OF rehab_presc_change.notes_change%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_rehab_presc_in      IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in           IN rehab_presc_change.id_change%TYPE,
        dt_change_in           IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        exec_per_session_in    IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        id_exec_institution_in IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        notes_in               IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        flg_status_change_in   IN rehab_presc_change.flg_status_change%TYPE DEFAULT 'W',
        id_prof_req_in         IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        dt_req_in              IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        id_prof_accept_in      IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        dt_accept_in           IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        id_prof_decline_in     IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        dt_decline_in          IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        notes_decline_in       IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        create_user_in         IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_time_in         IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_time_in         IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        notes_change_in        IN rehab_presc_change.notes_change%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_rehab_presc_in      IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in           IN rehab_presc_change.id_change%TYPE,
        dt_change_in           IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        exec_per_session_in    IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        id_exec_institution_in IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        notes_in               IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        flg_status_change_in   IN rehab_presc_change.flg_status_change%TYPE DEFAULT 'W',
        id_prof_req_in         IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        dt_req_in              IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        id_prof_accept_in      IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        dt_accept_in           IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        id_prof_decline_in     IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        dt_decline_in          IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        notes_decline_in       IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        create_user_in         IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_time_in         IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_time_in         IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        notes_change_in        IN rehab_presc_change.notes_change%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN rehab_presc_change%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN rehab_presc_change%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN rehab_presc_change_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN rehab_presc_change_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_rehab_presc_in       IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in            IN rehab_presc_change.id_change%TYPE,
        dt_change_in            IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        dt_change_nin           IN BOOLEAN := TRUE,
        flg_status_in           IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        exec_per_session_in     IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        exec_per_session_nin    IN BOOLEAN := TRUE,
        id_exec_institution_in  IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        id_exec_institution_nin IN BOOLEAN := TRUE,
        notes_in                IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        flg_status_change_in    IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        flg_status_change_nin   IN BOOLEAN := TRUE,
        id_prof_req_in          IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        id_prof_req_nin         IN BOOLEAN := TRUE,
        dt_req_in               IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        dt_req_nin              IN BOOLEAN := TRUE,
        id_prof_accept_in       IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        id_prof_accept_nin      IN BOOLEAN := TRUE,
        dt_accept_in            IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        dt_accept_nin           IN BOOLEAN := TRUE,
        id_prof_decline_in      IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        id_prof_decline_nin     IN BOOLEAN := TRUE,
        dt_decline_in           IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        dt_decline_nin          IN BOOLEAN := TRUE,
        notes_decline_in        IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        notes_decline_nin       IN BOOLEAN := TRUE,
        create_user_in          IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        notes_change_in         IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        notes_change_nin        IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_rehab_presc_in       IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in            IN rehab_presc_change.id_change%TYPE,
        dt_change_in            IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        dt_change_nin           IN BOOLEAN := TRUE,
        flg_status_in           IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        exec_per_session_in     IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        exec_per_session_nin    IN BOOLEAN := TRUE,
        id_exec_institution_in  IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        id_exec_institution_nin IN BOOLEAN := TRUE,
        notes_in                IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        flg_status_change_in    IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        flg_status_change_nin   IN BOOLEAN := TRUE,
        id_prof_req_in          IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        id_prof_req_nin         IN BOOLEAN := TRUE,
        dt_req_in               IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        dt_req_nin              IN BOOLEAN := TRUE,
        id_prof_accept_in       IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        id_prof_accept_nin      IN BOOLEAN := TRUE,
        dt_accept_in            IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        dt_accept_nin           IN BOOLEAN := TRUE,
        id_prof_decline_in      IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        id_prof_decline_nin     IN BOOLEAN := TRUE,
        dt_decline_in           IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        dt_decline_nin          IN BOOLEAN := TRUE,
        notes_decline_in        IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        notes_decline_nin       IN BOOLEAN := TRUE,
        create_user_in          IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        notes_change_in         IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        notes_change_nin        IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        dt_change_in            IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        dt_change_nin           IN BOOLEAN := TRUE,
        flg_status_in           IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        exec_per_session_in     IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        exec_per_session_nin    IN BOOLEAN := TRUE,
        id_exec_institution_in  IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        id_exec_institution_nin IN BOOLEAN := TRUE,
        notes_in                IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        flg_status_change_in    IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        flg_status_change_nin   IN BOOLEAN := TRUE,
        id_prof_req_in          IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        id_prof_req_nin         IN BOOLEAN := TRUE,
        dt_req_in               IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        dt_req_nin              IN BOOLEAN := TRUE,
        id_prof_accept_in       IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        id_prof_accept_nin      IN BOOLEAN := TRUE,
        dt_accept_in            IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        dt_accept_nin           IN BOOLEAN := TRUE,
        id_prof_decline_in      IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        id_prof_decline_nin     IN BOOLEAN := TRUE,
        dt_decline_in           IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        dt_decline_nin          IN BOOLEAN := TRUE,
        notes_decline_in        IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        notes_decline_nin       IN BOOLEAN := TRUE,
        create_user_in          IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        notes_change_in         IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        notes_change_nin        IN BOOLEAN := TRUE,
        where_in                VARCHAR2 DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    PROCEDURE upd
    (
        dt_change_in            IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        dt_change_nin           IN BOOLEAN := TRUE,
        flg_status_in           IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        exec_per_session_in     IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        exec_per_session_nin    IN BOOLEAN := TRUE,
        id_exec_institution_in  IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        id_exec_institution_nin IN BOOLEAN := TRUE,
        notes_in                IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        flg_status_change_in    IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        flg_status_change_nin   IN BOOLEAN := TRUE,
        id_prof_req_in          IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        id_prof_req_nin         IN BOOLEAN := TRUE,
        dt_req_in               IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        dt_req_nin              IN BOOLEAN := TRUE,
        id_prof_accept_in       IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        id_prof_accept_nin      IN BOOLEAN := TRUE,
        dt_accept_in            IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        dt_accept_nin           IN BOOLEAN := TRUE,
        id_prof_decline_in      IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        id_prof_decline_nin     IN BOOLEAN := TRUE,
        dt_decline_in           IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        dt_decline_nin          IN BOOLEAN := TRUE,
        notes_decline_in        IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        notes_decline_nin       IN BOOLEAN := TRUE,
        create_user_in          IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        notes_change_in         IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        notes_change_nin        IN BOOLEAN := TRUE,
        where_in                VARCHAR2 DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_rehab_presc_in      IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in           IN rehab_presc_change.id_change%TYPE,
        dt_change_in           IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        exec_per_session_in    IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        id_exec_institution_in IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        notes_in               IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        flg_status_change_in   IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        id_prof_req_in         IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        dt_req_in              IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        id_prof_accept_in      IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        dt_accept_in           IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        id_prof_decline_in     IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        dt_decline_in          IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        notes_decline_in       IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        create_user_in         IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_time_in         IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_time_in         IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        notes_change_in        IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_rehab_presc_in      IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in           IN rehab_presc_change.id_change%TYPE,
        dt_change_in           IN rehab_presc_change.dt_change%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_presc_change.flg_status%TYPE DEFAULT NULL,
        exec_per_session_in    IN rehab_presc_change.exec_per_session%TYPE DEFAULT NULL,
        id_exec_institution_in IN rehab_presc_change.id_exec_institution%TYPE DEFAULT NULL,
        notes_in               IN rehab_presc_change.notes%TYPE DEFAULT NULL,
        flg_status_change_in   IN rehab_presc_change.flg_status_change%TYPE DEFAULT NULL,
        id_prof_req_in         IN rehab_presc_change.id_prof_req%TYPE DEFAULT NULL,
        dt_req_in              IN rehab_presc_change.dt_req%TYPE DEFAULT NULL,
        id_prof_accept_in      IN rehab_presc_change.id_prof_accept%TYPE DEFAULT NULL,
        dt_accept_in           IN rehab_presc_change.dt_accept%TYPE DEFAULT NULL,
        id_prof_decline_in     IN rehab_presc_change.id_prof_decline%TYPE DEFAULT NULL,
        dt_decline_in          IN rehab_presc_change.dt_decline%TYPE DEFAULT NULL,
        notes_decline_in       IN rehab_presc_change.notes_decline%TYPE DEFAULT NULL,
        create_user_in         IN rehab_presc_change.create_user%TYPE DEFAULT NULL,
        create_time_in         IN rehab_presc_change.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN rehab_presc_change.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN rehab_presc_change.update_user%TYPE DEFAULT NULL,
        update_time_in         IN rehab_presc_change.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN rehab_presc_change.update_institution%TYPE DEFAULT NULL,
        notes_change_in        IN rehab_presc_change.notes_change%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_presc_change%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_presc_change%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN rehab_presc_change_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN rehab_presc_change_tc,
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
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in      IN rehab_presc_change.id_change%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        id_change_in      IN rehab_presc_change.id_change%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_REHAB_PRESC
    PROCEDURE del_id_rehab_presc
    (
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_REHAB_PRESC
    PROCEDURE del_id_rehab_presc
    (
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CHANGE
    PROCEDURE del_id_change
    (
        id_change_in    IN rehab_presc_change.id_change%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CHANGE
    PROCEDURE del_id_change
    (
        id_change_in    IN rehab_presc_change.id_change%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this RPCH_PL_FK foreign key value
    PROCEDURE del_rpch_pl_fk
    (
        id_prof_req_in  IN rehab_presc_change.id_prof_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RPCH_PL_FK foreign key value
    PROCEDURE del_rpch_pl_fk
    (
        id_prof_req_in  IN rehab_presc_change.id_prof_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this RPCH_PL_FK2 foreign key value
    PROCEDURE del_rpch_pl_fk2
    (
        id_prof_accept_in IN rehab_presc_change.id_prof_accept%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RPCH_PL_FK2 foreign key value
    PROCEDURE del_rpch_pl_fk2
    (
        id_prof_accept_in IN rehab_presc_change.id_prof_accept%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this RPCH_PL_FK3 foreign key value
    PROCEDURE del_rpch_pl_fk3
    (
        id_prof_decline_in IN rehab_presc_change.id_prof_decline%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RPCH_PL_FK3 foreign key value
    PROCEDURE del_rpch_pl_fk3
    (
        id_prof_decline_in IN rehab_presc_change.id_prof_decline%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this RPCH_RPC_FK foreign key value
    PROCEDURE del_rpch_rpc_fk
    (
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RPCH_RPC_FK foreign key value
    PROCEDURE del_rpch_rpc_fk
    (
        id_rehab_presc_in IN rehab_presc_change.id_rehab_presc%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
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
    PROCEDURE initrec(rehab_presc_change_inout IN OUT rehab_presc_change%ROWTYPE);

    FUNCTION initrec RETURN rehab_presc_change%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN rehab_presc_change_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN rehab_presc_change_tc;

END ts_rehab_presc_change;
/
