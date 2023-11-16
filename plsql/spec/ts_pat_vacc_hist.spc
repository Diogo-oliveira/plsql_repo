/*-- Last Change Revision: $Rev: 1592933 $*/
/*-- Last Change by: $Author: jorge.silva $*/
/*-- Date of last change: $Date: 2014-05-20 22:54:18 +0100 (ter, 20 mai 2014) $*/
CREATE OR REPLACE PACKAGE ts_pat_vacc_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 20, 2014 20:29:22
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "PAT_VACC_HIST"
    TYPE pat_vacc_hist_tc IS TABLE OF pat_vacc_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pat_vacc_hist_ntt IS TABLE OF pat_vacc_hist%ROWTYPE;
    TYPE pat_vacc_hist_vat IS VARRAY(100) OF pat_vacc_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF pat_vacc_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF pat_vacc_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF pat_vacc_hist%ROWTYPE;

    -- Column Collection based on column "ID_PAT_VACC_HIST"
    TYPE id_pat_vacc_hist_cc IS TABLE OF pat_vacc_hist.id_pat_vacc_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VACC"
    TYPE id_vacc_cc IS TABLE OF pat_vacc_hist.id_vacc%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PATIENT"
    TYPE id_patient_cc IS TABLE OF pat_vacc_hist.id_patient%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF pat_vacc_hist.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_STATUS"
    TYPE id_prof_status_cc IS TABLE OF pat_vacc_hist.id_prof_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_STATUS"
    TYPE dt_status_cc IS TABLE OF pat_vacc_hist.dt_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF pat_vacc_hist.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_REASON"
    TYPE id_reason_cc IS TABLE OF pat_vacc_hist.id_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF pat_vacc_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF pat_vacc_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF pat_vacc_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF pat_vacc_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF pat_vacc_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF pat_vacc_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_pat_vacc_hist_in   IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_pat_vacc_hist_in   IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN pat_vacc_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN pat_vacc_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN pat_vacc_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN pat_vacc_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN pat_vacc_hist.id_pat_vacc_hist%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        id_pat_vacc_hist_out  IN OUT pat_vacc_hist.id_pat_vacc_hist%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        id_pat_vacc_hist_out  IN OUT pat_vacc_hist.id_pat_vacc_hist%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN pat_vacc_hist.id_pat_vacc_hist%TYPE;

    FUNCTION ins
    (
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT 'A',
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN pat_vacc_hist.id_pat_vacc_hist%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_pat_vacc_hist_in    IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in             IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_vacc_nin            IN BOOLEAN := TRUE,
        id_patient_in          IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_status_in      IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        id_prof_status_nin     IN BOOLEAN := TRUE,
        dt_status_in           IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        dt_status_nin          IN BOOLEAN := TRUE,
        notes_in               IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        id_reason_in           IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        id_reason_nin          IN BOOLEAN := TRUE,
        create_user_in         IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_pat_vacc_hist_in    IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in             IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_vacc_nin            IN BOOLEAN := TRUE,
        id_patient_in          IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_status_in      IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        id_prof_status_nin     IN BOOLEAN := TRUE,
        dt_status_in           IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        dt_status_nin          IN BOOLEAN := TRUE,
        notes_in               IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        id_reason_in           IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        id_reason_nin          IN BOOLEAN := TRUE,
        create_user_in         IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_vacc_in             IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_vacc_nin            IN BOOLEAN := TRUE,
        id_patient_in          IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_status_in      IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        id_prof_status_nin     IN BOOLEAN := TRUE,
        dt_status_in           IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        dt_status_nin          IN BOOLEAN := TRUE,
        notes_in               IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        id_reason_in           IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        id_reason_nin          IN BOOLEAN := TRUE,
        create_user_in         IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vacc_in             IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_vacc_nin            IN BOOLEAN := TRUE,
        id_patient_in          IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        id_patient_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_status_in      IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        id_prof_status_nin     IN BOOLEAN := TRUE,
        dt_status_in           IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        dt_status_nin          IN BOOLEAN := TRUE,
        notes_in               IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        id_reason_in           IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        id_reason_nin          IN BOOLEAN := TRUE,
        create_user_in         IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_pat_vacc_hist_in   IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_pat_vacc_hist_in   IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        id_vacc_in            IN pat_vacc_hist.id_vacc%TYPE DEFAULT NULL,
        id_patient_in         IN pat_vacc_hist.id_patient%TYPE DEFAULT NULL,
        flg_status_in         IN pat_vacc_hist.flg_status%TYPE DEFAULT NULL,
        id_prof_status_in     IN pat_vacc_hist.id_prof_status%TYPE DEFAULT NULL,
        dt_status_in          IN pat_vacc_hist.dt_status%TYPE DEFAULT NULL,
        notes_in              IN pat_vacc_hist.notes%TYPE DEFAULT NULL,
        id_reason_in          IN pat_vacc_hist.id_reason%TYPE DEFAULT NULL,
        create_user_in        IN pat_vacc_hist.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pat_vacc_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pat_vacc_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pat_vacc_hist.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pat_vacc_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pat_vacc_hist.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN pat_vacc_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN pat_vacc_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN pat_vacc_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN pat_vacc_hist_tc,
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
        id_pat_vacc_hist_in IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pat_vacc_hist_in IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for primary key column ID_PAT_VACC_HIST
    PROCEDURE del_id_pat_vacc_hist
    (
        id_pat_vacc_hist_in IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_PAT_VACC_HIST
    PROCEDURE del_id_pat_vacc_hist
    (
        id_pat_vacc_hist_in IN pat_vacc_hist.id_pat_vacc_hist%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PVH_PAT_PK foreign key value
    PROCEDURE del_pvh_pat_pk
    (
        id_patient_in   IN pat_vacc_hist.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PVH_PAT_PK foreign key value
    PROCEDURE del_pvh_pat_pk
    (
        id_patient_in   IN pat_vacc_hist.id_patient%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PVH_PROF_STAT_PK foreign key value
    PROCEDURE del_pvh_prof_stat_pk
    (
        id_prof_status_in IN pat_vacc_hist.id_prof_status%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PVH_PROF_STAT_PK foreign key value
    PROCEDURE del_pvh_prof_stat_pk
    (
        id_prof_status_in IN pat_vacc_hist.id_prof_status%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this PVH_REASON_PK foreign key value
    PROCEDURE del_pvh_reason_pk
    (
        id_reason_in    IN pat_vacc_hist.id_reason%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PVH_REASON_PK foreign key value
    PROCEDURE del_pvh_reason_pk
    (
        id_reason_in    IN pat_vacc_hist.id_reason%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PVH_VACC foreign key value
    PROCEDURE del_pvh_vacc
    (
        id_vacc_in      IN pat_vacc_hist.id_vacc%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PVH_VACC foreign key value
    PROCEDURE del_pvh_vacc
    (
        id_vacc_in      IN pat_vacc_hist.id_vacc%TYPE,
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
    PROCEDURE initrec(pat_vacc_hist_inout IN OUT pat_vacc_hist%ROWTYPE);

    FUNCTION initrec RETURN pat_vacc_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pat_vacc_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pat_vacc_hist_tc;

END ts_pat_vacc_hist;
/