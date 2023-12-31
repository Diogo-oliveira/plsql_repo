/*-- Last Change Revision: $Rev: 2029355 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_rehab_schedule
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Julho 14, 2010 15:41:32
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "REHAB_SCHEDULE"
    TYPE rehab_schedule_tc IS TABLE OF rehab_schedule%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE rehab_schedule_ntt IS TABLE OF rehab_schedule%ROWTYPE;
    TYPE rehab_schedule_vat IS VARRAY(100) OF rehab_schedule%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF rehab_schedule%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF rehab_schedule%ROWTYPE;
    TYPE vat IS VARRAY(100) OF rehab_schedule%ROWTYPE;

    -- Column Collection based on column "ID_REHAB_SCHEDULE"
    TYPE id_rehab_schedule_cc IS TABLE OF rehab_schedule.id_rehab_schedule%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_REHAB_SCH_NEED"
    TYPE id_rehab_sch_need_cc IS TABLE OF rehab_schedule.id_rehab_sch_need%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF rehab_schedule.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SCHEDULE"
    TYPE id_schedule_cc IS TABLE OF rehab_schedule.id_schedule%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_SCHEDULE"
    TYPE dt_schedule_cc IS TABLE OF rehab_schedule.dt_schedule%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF rehab_schedule.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CANCEL_REASON"
    TYPE id_cancel_reason_cc IS TABLE OF rehab_schedule.id_cancel_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CANCEL"
    TYPE dt_cancel_cc IS TABLE OF rehab_schedule.dt_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_CANCEL_PROF"
    TYPE id_cancel_prof_cc IS TABLE OF rehab_schedule.id_cancel_prof%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "NOTES"
    TYPE notes_cc IS TABLE OF rehab_schedule.notes%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF rehab_schedule.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF rehab_schedule.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF rehab_schedule.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF rehab_schedule.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF rehab_schedule.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF rehab_schedule.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_rehab_schedule_in  IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_rehab_schedule_in  IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN rehab_schedule%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN rehab_schedule%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN rehab_schedule_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN rehab_schedule_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN rehab_schedule.id_rehab_schedule%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        id_rehab_schedule_out IN OUT rehab_schedule.id_rehab_schedule%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        id_rehab_schedule_out IN OUT rehab_schedule.id_rehab_schedule%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN rehab_schedule.id_rehab_schedule%TYPE;

    FUNCTION ins
    (
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN rehab_schedule.id_rehab_schedule%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_rehab_schedule_in   IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in   IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_rehab_sch_need_nin  IN BOOLEAN := TRUE,
        id_professional_in     IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_schedule_in         IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin        IN BOOLEAN := TRUE,
        dt_schedule_in         IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        dt_schedule_nin        IN BOOLEAN := TRUE,
        flg_status_in          IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        dt_cancel_in           IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin          IN BOOLEAN := TRUE,
        id_cancel_prof_in      IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        id_cancel_prof_nin     IN BOOLEAN := TRUE,
        notes_in               IN rehab_schedule.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        create_user_in         IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_rehab_schedule_in   IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in   IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_rehab_sch_need_nin  IN BOOLEAN := TRUE,
        id_professional_in     IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_schedule_in         IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin        IN BOOLEAN := TRUE,
        dt_schedule_in         IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        dt_schedule_nin        IN BOOLEAN := TRUE,
        flg_status_in          IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        dt_cancel_in           IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin          IN BOOLEAN := TRUE,
        id_cancel_prof_in      IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        id_cancel_prof_nin     IN BOOLEAN := TRUE,
        notes_in               IN rehab_schedule.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        create_user_in         IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_rehab_sch_need_in   IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_rehab_sch_need_nin  IN BOOLEAN := TRUE,
        id_professional_in     IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_schedule_in         IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin        IN BOOLEAN := TRUE,
        dt_schedule_in         IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        dt_schedule_nin        IN BOOLEAN := TRUE,
        flg_status_in          IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        dt_cancel_in           IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin          IN BOOLEAN := TRUE,
        id_cancel_prof_in      IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        id_cancel_prof_nin     IN BOOLEAN := TRUE,
        notes_in               IN rehab_schedule.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        create_user_in         IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_rehab_sch_need_in   IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_rehab_sch_need_nin  IN BOOLEAN := TRUE,
        id_professional_in     IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_schedule_in         IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin        IN BOOLEAN := TRUE,
        dt_schedule_in         IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        dt_schedule_nin        IN BOOLEAN := TRUE,
        flg_status_in          IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in    IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin   IN BOOLEAN := TRUE,
        dt_cancel_in           IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin          IN BOOLEAN := TRUE,
        id_cancel_prof_in      IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        id_cancel_prof_nin     IN BOOLEAN := TRUE,
        notes_in               IN rehab_schedule.notes%TYPE DEFAULT NULL,
        notes_nin              IN BOOLEAN := TRUE,
        create_user_in         IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_rehab_schedule_in  IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_rehab_schedule_in  IN rehab_schedule.id_rehab_schedule%TYPE,
        id_rehab_sch_need_in  IN rehab_schedule.id_rehab_sch_need%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_schedule.id_professional%TYPE DEFAULT NULL,
        id_schedule_in        IN rehab_schedule.id_schedule%TYPE DEFAULT NULL,
        dt_schedule_in        IN rehab_schedule.dt_schedule%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_schedule.flg_status%TYPE DEFAULT NULL,
        id_cancel_reason_in   IN rehab_schedule.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in          IN rehab_schedule.dt_cancel%TYPE DEFAULT NULL,
        id_cancel_prof_in     IN rehab_schedule.id_cancel_prof%TYPE DEFAULT NULL,
        notes_in              IN rehab_schedule.notes%TYPE DEFAULT NULL,
        create_user_in        IN rehab_schedule.create_user%TYPE DEFAULT NULL,
        create_time_in        IN rehab_schedule.create_time%TYPE DEFAULT NULL,
        create_institution_in IN rehab_schedule.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN rehab_schedule.update_user%TYPE DEFAULT NULL,
        update_time_in        IN rehab_schedule.update_time%TYPE DEFAULT NULL,
        update_institution_in IN rehab_schedule.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_schedule%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN rehab_schedule%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN rehab_schedule_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN rehab_schedule_tc,
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
        id_rehab_schedule_in IN rehab_schedule.id_rehab_schedule%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_rehab_schedule_in IN rehab_schedule.id_rehab_schedule%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for primary key column ID_REHAB_SCHEDULE
    PROCEDURE del_id_rehab_schedule
    (
        id_rehab_schedule_in IN rehab_schedule.id_rehab_schedule%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_REHAB_SCHEDULE
    PROCEDURE del_id_rehab_schedule
    (
        id_rehab_schedule_in IN rehab_schedule.id_rehab_schedule%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this RSC_PL_FK foreign key value
    PROCEDURE del_rsc_pl_fk
    (
        id_professional_in IN rehab_schedule.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RSC_PL_FK foreign key value
    PROCEDURE del_rsc_pl_fk
    (
        id_professional_in IN rehab_schedule.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this RSC_PL_FK2 foreign key value
    PROCEDURE del_rsc_pl_fk2
    (
        id_cancel_prof_in IN rehab_schedule.id_cancel_prof%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RSC_PL_FK2 foreign key value
    PROCEDURE del_rsc_pl_fk2
    (
        id_cancel_prof_in IN rehab_schedule.id_cancel_prof%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this RSC_RSD_FK foreign key value
    PROCEDURE del_rsc_rsd_fk
    (
        id_rehab_sch_need_in IN rehab_schedule.id_rehab_sch_need%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RSC_RSD_FK foreign key value
    PROCEDURE del_rsc_rsd_fk
    (
        id_rehab_sch_need_in IN rehab_schedule.id_rehab_sch_need%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
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
    PROCEDURE initrec(rehab_schedule_inout IN OUT rehab_schedule%ROWTYPE);

    FUNCTION initrec RETURN rehab_schedule%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN rehab_schedule_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN rehab_schedule_tc;

END ts_rehab_schedule;
/
