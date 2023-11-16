/*-- Last Change Revision: $Rev: 1811685 $*/
/*-- Last Change by: $Author: rui.mendonca $*/
/*-- Date of last change: $Date: 2017-12-15 16:07:18 +0000 (sex, 15 dez 2017) $*/
CREATE OR REPLACE PACKAGE ts_epis_pn_addendum_hist
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-12-12 15:33:43
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on epis_pn_addendum_hist
    TYPE epis_pn_addendum_hist_tc IS TABLE OF epis_pn_addendum_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_pn_addendum_hist_ntt IS TABLE OF epis_pn_addendum_hist%ROWTYPE;
    TYPE epis_pn_addendum_hist_vat IS VARRAY(100) OF epis_pn_addendum_hist%ROWTYPE;

    -- Column Collection based on column ID_EPIS_PN_ADDENDUM
    TYPE id_epis_pn_addendum_cc IS TABLE OF epis_pn_addendum_hist.id_epis_pn_addendum%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_EPIS_ADDENDUM_HIST
    TYPE dt_epis_addendum_hist_cc IS TABLE OF epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_EPIS_PN
    TYPE id_epis_pn_cc IS TABLE OF epis_pn_addendum_hist.id_epis_pn%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_STATUS
    TYPE flg_status_cc IS TABLE OF epis_pn_addendum_hist.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PROFESSIONAL
    TYPE id_professional_cc IS TABLE OF epis_pn_addendum_hist.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_ADDENDUM
    TYPE dt_addendum_cc IS TABLE OF epis_pn_addendum_hist.dt_addendum%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column PN_ADDENDUM
    TYPE pn_addendum_cc IS TABLE OF epis_pn_addendum_hist.pn_addendum%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_LAST_UPDATE
    TYPE dt_last_update_cc IS TABLE OF epis_pn_addendum_hist.dt_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PROF_LAST_UPDATE
    TYPE id_prof_last_update_cc IS TABLE OF epis_pn_addendum_hist.id_prof_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_SIGNOFF
    TYPE dt_signoff_cc IS TABLE OF epis_pn_addendum_hist.dt_signoff%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PROF_SIGNOFF
    TYPE id_prof_signoff_cc IS TABLE OF epis_pn_addendum_hist.id_prof_signoff%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PROF_CANCEL
    TYPE id_prof_cancel_cc IS TABLE OF epis_pn_addendum_hist.id_prof_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_CANCEL_REASON
    TYPE id_cancel_reason_cc IS TABLE OF epis_pn_addendum_hist.id_cancel_reason%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_CANCEL
    TYPE dt_cancel_cc IS TABLE OF epis_pn_addendum_hist.dt_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column NOTES_CANCEL
    TYPE notes_cancel_cc IS TABLE OF epis_pn_addendum_hist.notes_cancel%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF epis_pn_addendum_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF epis_pn_addendum_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF epis_pn_addendum_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF epis_pn_addendum_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF epis_pn_addendum_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF epis_pn_addendum_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_TYPE
    TYPE flg_type_cc IS TABLE OF epis_pn_addendum_hist.flg_type%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT 'A',
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT 'A',
        handle_error_in          IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN epis_pn_addendum_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN epis_pn_addendum_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN epis_pn_addendum_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN epis_pn_addendum_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        id_epis_pn_nin           IN BOOLEAN := TRUE,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        id_professional_nin      IN BOOLEAN := TRUE,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        dt_addendum_nin          IN BOOLEAN := TRUE,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        pn_addendum_nin          IN BOOLEAN := TRUE,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        dt_last_update_nin       IN BOOLEAN := TRUE,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_nin  IN BOOLEAN := TRUE,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        dt_signoff_nin           IN BOOLEAN := TRUE,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_nin      IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin     IN BOOLEAN := TRUE,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        flg_type_nin             IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        id_epis_pn_nin           IN BOOLEAN := TRUE,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        id_professional_nin      IN BOOLEAN := TRUE,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        dt_addendum_nin          IN BOOLEAN := TRUE,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        pn_addendum_nin          IN BOOLEAN := TRUE,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        dt_last_update_nin       IN BOOLEAN := TRUE,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_nin  IN BOOLEAN := TRUE,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        dt_signoff_nin           IN BOOLEAN := TRUE,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_nin      IN BOOLEAN := TRUE,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin       IN BOOLEAN := TRUE,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin     IN BOOLEAN := TRUE,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin            IN BOOLEAN := TRUE,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin         IN BOOLEAN := TRUE,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        flg_type_nin             IN BOOLEAN := TRUE,
        handle_error_in          IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_epis_pn_in           IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        id_epis_pn_nin          IN BOOLEAN := TRUE,
        flg_status_in           IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        id_professional_in      IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        id_professional_nin     IN BOOLEAN := TRUE,
        dt_addendum_in          IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        dt_addendum_nin         IN BOOLEAN := TRUE,
        pn_addendum_in          IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        pn_addendum_nin         IN BOOLEAN := TRUE,
        dt_last_update_in       IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        dt_last_update_nin      IN BOOLEAN := TRUE,
        id_prof_last_update_in  IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_nin IN BOOLEAN := TRUE,
        dt_signoff_in           IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        dt_signoff_nin          IN BOOLEAN := TRUE,
        id_prof_signoff_in      IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_nin     IN BOOLEAN := TRUE,
        id_prof_cancel_in       IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin      IN BOOLEAN := TRUE,
        id_cancel_reason_in     IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin    IN BOOLEAN := TRUE,
        dt_cancel_in            IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin           IN BOOLEAN := TRUE,
        notes_cancel_in         IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin        IN BOOLEAN := TRUE,
        create_user_in          IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_type_in             IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        flg_type_nin            IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_epis_pn_in           IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        id_epis_pn_nin          IN BOOLEAN := TRUE,
        flg_status_in           IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        flg_status_nin          IN BOOLEAN := TRUE,
        id_professional_in      IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        id_professional_nin     IN BOOLEAN := TRUE,
        dt_addendum_in          IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        dt_addendum_nin         IN BOOLEAN := TRUE,
        pn_addendum_in          IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        pn_addendum_nin         IN BOOLEAN := TRUE,
        dt_last_update_in       IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        dt_last_update_nin      IN BOOLEAN := TRUE,
        id_prof_last_update_in  IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_nin IN BOOLEAN := TRUE,
        dt_signoff_in           IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        dt_signoff_nin          IN BOOLEAN := TRUE,
        id_prof_signoff_in      IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_nin     IN BOOLEAN := TRUE,
        id_prof_cancel_in       IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin      IN BOOLEAN := TRUE,
        id_cancel_reason_in     IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin    IN BOOLEAN := TRUE,
        dt_cancel_in            IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        dt_cancel_nin           IN BOOLEAN := TRUE,
        notes_cancel_in         IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin        IN BOOLEAN := TRUE,
        create_user_in          IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        flg_type_in             IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        flg_type_nin            IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        id_epis_pn_in            IN epis_pn_addendum_hist.id_epis_pn%TYPE DEFAULT NULL,
        flg_status_in            IN epis_pn_addendum_hist.flg_status%TYPE DEFAULT NULL,
        id_professional_in       IN epis_pn_addendum_hist.id_professional%TYPE DEFAULT NULL,
        dt_addendum_in           IN epis_pn_addendum_hist.dt_addendum%TYPE DEFAULT NULL,
        pn_addendum_in           IN epis_pn_addendum_hist.pn_addendum%TYPE DEFAULT NULL,
        dt_last_update_in        IN epis_pn_addendum_hist.dt_last_update%TYPE DEFAULT NULL,
        id_prof_last_update_in   IN epis_pn_addendum_hist.id_prof_last_update%TYPE DEFAULT NULL,
        dt_signoff_in            IN epis_pn_addendum_hist.dt_signoff%TYPE DEFAULT NULL,
        id_prof_signoff_in       IN epis_pn_addendum_hist.id_prof_signoff%TYPE DEFAULT NULL,
        id_prof_cancel_in        IN epis_pn_addendum_hist.id_prof_cancel%TYPE DEFAULT NULL,
        id_cancel_reason_in      IN epis_pn_addendum_hist.id_cancel_reason%TYPE DEFAULT NULL,
        dt_cancel_in             IN epis_pn_addendum_hist.dt_cancel%TYPE DEFAULT NULL,
        notes_cancel_in          IN epis_pn_addendum_hist.notes_cancel%TYPE DEFAULT NULL,
        create_user_in           IN epis_pn_addendum_hist.create_user%TYPE DEFAULT NULL,
        create_time_in           IN epis_pn_addendum_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in    IN epis_pn_addendum_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in           IN epis_pn_addendum_hist.update_user%TYPE DEFAULT NULL,
        update_time_in           IN epis_pn_addendum_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in    IN epis_pn_addendum_hist.update_institution%TYPE DEFAULT NULL,
        flg_type_in              IN epis_pn_addendum_hist.flg_type%TYPE DEFAULT NULL,
        handle_error_in          IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN epis_pn_addendum_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN epis_pn_addendum_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN epis_pn_addendum_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN epis_pn_addendum_hist_tc,
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
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_pn_addendum_in   IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        dt_epis_addendum_hist_in IN epis_pn_addendum_hist.dt_epis_addendum_hist%TYPE,
        handle_error_in          IN BOOLEAN := TRUE
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

    -- Delete all rows for this EPT_EPMA_FK foreign key value
    PROCEDURE del_ept_epma_fk
    (
        id_epis_pn_addendum_in IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this EPT_EPMA_FK foreign key value
    PROCEDURE del_ept_epma_fk
    (
        id_epis_pn_addendum_in IN epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(epis_pn_addendum_hist_inout IN OUT epis_pn_addendum_hist%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN epis_pn_addendum_hist%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_pn_addendum_hist_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_pn_addendum_hist_tc;

END ts_epis_pn_addendum_hist;
/