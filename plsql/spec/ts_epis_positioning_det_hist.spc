/*-- Last Change Revision: $Rev: 2029173 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:12 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE ts_epis_positioning_det_hist
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Abril 18, 2011 12:32:0
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_POSITIONING_DET_HIST"
    TYPE epis_positioning_det_hist_tc IS TABLE OF epis_positioning_det_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_positioning_det_hist_ntt IS TABLE OF epis_positioning_det_hist%ROWTYPE;
    TYPE epis_positioning_det_hist_vat IS VARRAY(100) OF epis_positioning_det_hist%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_positioning_det_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_positioning_det_hist%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_positioning_det_hist%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_POSIT_DET_HIST"
    TYPE id_epis_posit_det_hist_cc IS TABLE OF epis_positioning_det_hist.id_epis_posit_det_hist%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPIS_POSITIONING_DET"
    TYPE id_epis_positioning_det_cc IS TABLE OF epis_positioning_det_hist.id_epis_positioning_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPIS_POSITIONING"
    TYPE id_epis_positioning_cc IS TABLE OF epis_positioning_det_hist.id_epis_positioning%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_POSITIONING"
    TYPE id_positioning_cc IS TABLE OF epis_positioning_det_hist.id_positioning%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "RANK"
    TYPE rank_cc IS TABLE OF epis_positioning_det_hist.rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_positioning_det_hist.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_positioning_det_hist.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_positioning_det_hist.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_positioning_det_hist.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_positioning_det_hist.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_positioning_det_hist.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_LAST_UPD"
    TYPE id_prof_last_upd_cc IS TABLE OF epis_positioning_det_hist.id_prof_last_upd%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_EPIS_POSITIONING_DET"
    TYPE dt_epis_positioning_det_cc IS TABLE OF epis_positioning_det_hist.dt_epis_positioning_det%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_OUTDATED"
    TYPE flg_outdated_cc IS TABLE OF epis_positioning_det_hist.flg_outdated%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_posit_det_hist_in  IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_posit_det_hist_in  IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN epis_positioning_det_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_positioning_det_hist%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_positioning_det_hist_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_positioning_det_hist_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N',
        id_epis_posit_det_hist_out IN OUT epis_positioning_det_hist.id_epis_posit_det_hist%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N',
        id_epis_posit_det_hist_out IN OUT epis_positioning_det_hist.id_epis_posit_det_hist%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE;

    FUNCTION ins
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT 'N'
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_posit_det_hist_in   IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in  IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_det_nin IN BOOLEAN := TRUE,
        id_epis_positioning_in      IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_epis_positioning_nin     IN BOOLEAN := TRUE,
        id_positioning_in           IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        id_positioning_nin          IN BOOLEAN := TRUE,
        rank_in                     IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        create_user_in              IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_prof_last_upd_in         IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        id_prof_last_upd_nin        IN BOOLEAN := TRUE,
        dt_epis_positioning_det_in  IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        dt_epis_positioning_det_nin IN BOOLEAN := TRUE,
        flg_outdated_in             IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        flg_outdated_nin            IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_posit_det_hist_in   IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in  IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_det_nin IN BOOLEAN := TRUE,
        id_epis_positioning_in      IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_epis_positioning_nin     IN BOOLEAN := TRUE,
        id_positioning_in           IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        id_positioning_nin          IN BOOLEAN := TRUE,
        rank_in                     IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        create_user_in              IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_prof_last_upd_in         IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        id_prof_last_upd_nin        IN BOOLEAN := TRUE,
        dt_epis_positioning_det_in  IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        dt_epis_positioning_det_nin IN BOOLEAN := TRUE,
        flg_outdated_in             IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        flg_outdated_nin            IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_epis_positioning_det_in  IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_det_nin IN BOOLEAN := TRUE,
        id_epis_positioning_in      IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_epis_positioning_nin     IN BOOLEAN := TRUE,
        id_positioning_in           IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        id_positioning_nin          IN BOOLEAN := TRUE,
        rank_in                     IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        create_user_in              IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_prof_last_upd_in         IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        id_prof_last_upd_nin        IN BOOLEAN := TRUE,
        dt_epis_positioning_det_in  IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        dt_epis_positioning_det_nin IN BOOLEAN := TRUE,
        flg_outdated_in             IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        flg_outdated_nin            IN BOOLEAN := TRUE,
        where_in                    VARCHAR2 DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_positioning_det_in  IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_det_nin IN BOOLEAN := TRUE,
        id_epis_positioning_in      IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_epis_positioning_nin     IN BOOLEAN := TRUE,
        id_positioning_in           IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        id_positioning_nin          IN BOOLEAN := TRUE,
        rank_in                     IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        create_user_in              IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        id_prof_last_upd_in         IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        id_prof_last_upd_nin        IN BOOLEAN := TRUE,
        dt_epis_positioning_det_in  IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        dt_epis_positioning_det_nin IN BOOLEAN := TRUE,
        flg_outdated_in             IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        flg_outdated_nin            IN BOOLEAN := TRUE,
        where_in                    VARCHAR2 DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_posit_det_hist_in  IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_posit_det_hist_in  IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE DEFAULT NULL,
        id_epis_positioning_in     IN epis_positioning_det_hist.id_epis_positioning%TYPE DEFAULT NULL,
        id_positioning_in          IN epis_positioning_det_hist.id_positioning%TYPE DEFAULT NULL,
        rank_in                    IN epis_positioning_det_hist.rank%TYPE DEFAULT NULL,
        create_user_in             IN epis_positioning_det_hist.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_positioning_det_hist.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_positioning_det_hist.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_positioning_det_hist.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_positioning_det_hist.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_positioning_det_hist.update_institution%TYPE DEFAULT NULL,
        id_prof_last_upd_in        IN epis_positioning_det_hist.id_prof_last_upd%TYPE DEFAULT NULL,
        dt_epis_positioning_det_in IN epis_positioning_det_hist.dt_epis_positioning_det%TYPE DEFAULT NULL,
        flg_outdated_in            IN epis_positioning_det_hist.flg_outdated%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_positioning_det_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_positioning_det_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_positioning_det_hist_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_positioning_det_hist_tc,
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
        id_epis_posit_det_hist_in IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_posit_det_hist_in IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_POSIT_DET_HIST
    PROCEDURE del_id_epis_posit_det_hist
    (
        id_epis_posit_det_hist_in IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_POSIT_DET_HIST
    PROCEDURE del_id_epis_posit_det_hist
    (
        id_epis_posit_det_hist_in IN epis_positioning_det_hist.id_epis_posit_det_hist%TYPE,
        handle_error_in           IN BOOLEAN := TRUE,
        rows_out                  OUT table_varchar
    );

    -- Delete all rows for this EPGDH_EPGD_FK foreign key value
    PROCEDURE del_epgdh_epgd_fk
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EPGDH_EPGD_FK foreign key value
    PROCEDURE del_epgdh_epgd_fk
    (
        id_epis_positioning_det_in IN epis_positioning_det_hist.id_epis_positioning_det%TYPE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    -- Delete all rows for this EPGDH_EPG_FK foreign key value
    PROCEDURE del_epgdh_epg_fk
    (
        id_epis_positioning_in IN epis_positioning_det_hist.id_epis_positioning%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EPGDH_EPG_FK foreign key value
    PROCEDURE del_epgdh_epg_fk
    (
        id_epis_positioning_in IN epis_positioning_det_hist.id_epis_positioning%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this EPGDH_POG_FK foreign key value
    PROCEDURE del_epgdh_pog_fk
    (
        id_positioning_in IN epis_positioning_det_hist.id_positioning%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EPGDH_POG_FK foreign key value
    PROCEDURE del_epgdh_pog_fk
    (
        id_positioning_in IN epis_positioning_det_hist.id_positioning%TYPE,
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
    PROCEDURE initrec(epis_posit_det_hist_inout IN OUT epis_positioning_det_hist%ROWTYPE);

    FUNCTION initrec RETURN epis_positioning_det_hist%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_positioning_det_hist_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_positioning_det_hist_tc;

END ts_epis_positioning_det_hist;
/
