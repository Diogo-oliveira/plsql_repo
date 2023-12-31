/*-- Last Change Revision: $Rev: 2029206 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_icnp_cplan_stand
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Setembro 28, 2010 16:55:24
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "ICNP_CPLAN_STAND"
    TYPE icnp_cplan_stand_tc IS TABLE OF icnp_cplan_stand%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE icnp_cplan_stand_ntt IS TABLE OF icnp_cplan_stand%ROWTYPE;
    TYPE icnp_cplan_stand_vat IS VARRAY(100) OF icnp_cplan_stand%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF icnp_cplan_stand%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF icnp_cplan_stand%ROWTYPE;
    TYPE vat IS VARRAY(100) OF icnp_cplan_stand%ROWTYPE;

    -- Column Collection based on column "ID_CPLAN_STAND"
    TYPE id_cplan_stand_cc IS TABLE OF icnp_cplan_stand.id_cplan_stand%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NAME"
    TYPE name_cc IS TABLE OF icnp_cplan_stand.name%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF icnp_cplan_stand.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF icnp_cplan_stand.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CARE_PLAN_STAND"
    TYPE dt_care_plan_stand_cc IS TABLE OF icnp_cplan_stand.dt_care_plan_stand%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF icnp_cplan_stand.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF icnp_cplan_stand.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF icnp_cplan_stand.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF icnp_cplan_stand.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF icnp_cplan_stand.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF icnp_cplan_stand.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF icnp_cplan_stand.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF icnp_cplan_stand.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_cplan_stand_in     IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_cplan_stand_in     IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN icnp_cplan_stand%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN icnp_cplan_stand%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN icnp_cplan_stand_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN icnp_cplan_stand_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN icnp_cplan_stand.id_cplan_stand%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        id_cplan_stand_out    IN OUT icnp_cplan_stand.id_cplan_stand%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        id_cplan_stand_out    IN OUT icnp_cplan_stand.id_cplan_stand%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN icnp_cplan_stand.id_cplan_stand%TYPE;

    FUNCTION ins
    (
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN icnp_cplan_stand.id_cplan_stand%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_cplan_stand_in      IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in                IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        name_nin               IN BOOLEAN := TRUE,
        notes_in               IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        flg_status_in          IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        dt_care_plan_stand_in  IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        dt_care_plan_stand_nin IN BOOLEAN := TRUE,
        id_professional_in     IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_institution_in      IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        create_user_in         IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_cplan_stand_in      IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in                IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        name_nin               IN BOOLEAN := TRUE,
        notes_in               IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        flg_status_in          IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        dt_care_plan_stand_in  IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        dt_care_plan_stand_nin IN BOOLEAN := TRUE,
        id_professional_in     IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_institution_in      IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        create_user_in         IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        name_in                IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        name_nin               IN BOOLEAN := TRUE,
        notes_in               IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        flg_status_in          IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        dt_care_plan_stand_in  IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        dt_care_plan_stand_nin IN BOOLEAN := TRUE,
        id_professional_in     IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_institution_in      IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        create_user_in         IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        name_in                IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        name_nin               IN BOOLEAN := TRUE,
        notes_in               IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        flg_status_in          IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        dt_care_plan_stand_in  IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        dt_care_plan_stand_nin IN BOOLEAN := TRUE,
        id_professional_in     IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_institution_in      IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        create_user_in         IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_cplan_stand_in     IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_cplan_stand_in     IN icnp_cplan_stand.id_cplan_stand%TYPE,
        name_in               IN icnp_cplan_stand.name%TYPE DEFAULT NULL,
        notes_in              IN icnp_cplan_stand.notes%TYPE DEFAULT NULL,
        flg_status_in         IN icnp_cplan_stand.flg_status%TYPE DEFAULT NULL,
        dt_care_plan_stand_in IN icnp_cplan_stand.dt_care_plan_stand%TYPE DEFAULT NULL,
        id_professional_in    IN icnp_cplan_stand.id_professional%TYPE DEFAULT NULL,
        id_institution_in     IN icnp_cplan_stand.id_institution%TYPE DEFAULT NULL,
        create_user_in        IN icnp_cplan_stand.create_user%TYPE DEFAULT NULL,
        create_time_in        IN icnp_cplan_stand.create_time%TYPE DEFAULT NULL,
        create_institution_in IN icnp_cplan_stand.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN icnp_cplan_stand.update_user%TYPE DEFAULT NULL,
        update_time_in        IN icnp_cplan_stand.update_time%TYPE DEFAULT NULL,
        update_institution_in IN icnp_cplan_stand.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN icnp_cplan_stand%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN icnp_cplan_stand%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN icnp_cplan_stand_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN icnp_cplan_stand_tc,
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
        id_cplan_stand_in IN icnp_cplan_stand.id_cplan_stand%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_cplan_stand_in IN icnp_cplan_stand.id_cplan_stand%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CPLAN_STAND
    PROCEDURE del_id_cplan_stand
    (
        id_cplan_stand_in IN icnp_cplan_stand.id_cplan_stand%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CPLAN_STAND
    PROCEDURE del_id_cplan_stand
    (
        id_cplan_stand_in IN icnp_cplan_stand.id_cplan_stand%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this ICPS_INN_FK foreign key value
    PROCEDURE del_icps_inn_fk
    (
        id_institution_in IN icnp_cplan_stand.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICPS_INN_FK foreign key value
    PROCEDURE del_icps_inn_fk
    (
        id_institution_in IN icnp_cplan_stand.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this ICPS_PRL_FK foreign key value
    PROCEDURE del_icps_prl_fk
    (
        id_professional_in IN icnp_cplan_stand.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this ICPS_PRL_FK foreign key value
    PROCEDURE del_icps_prl_fk
    (
        id_professional_in IN icnp_cplan_stand.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
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
    PROCEDURE initrec(icnp_cplan_stand_inout IN OUT icnp_cplan_stand%ROWTYPE);

    FUNCTION initrec RETURN icnp_cplan_stand%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN icnp_cplan_stand_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN icnp_cplan_stand_tc;

END ts_icnp_cplan_stand;
/
