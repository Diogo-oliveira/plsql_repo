/*-- Last Change Revision: $Rev: 2029125 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_epis_abcde_meth_param
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: July 5, 2009 17:16:46
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "EPIS_ABCDE_METH_PARAM"
    TYPE epis_abcde_meth_param_tc IS TABLE OF epis_abcde_meth_param%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_abcde_meth_param_ntt IS TABLE OF epis_abcde_meth_param%ROWTYPE;
    TYPE epis_abcde_meth_param_vat IS VARRAY(100) OF epis_abcde_meth_param%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF epis_abcde_meth_param%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF epis_abcde_meth_param%ROWTYPE;
    TYPE vat IS VARRAY(100) OF epis_abcde_meth_param%ROWTYPE;

    -- Column Collection based on column "ID_EPIS_ABCDE_METH_PARAM"
    TYPE id_epis_abcde_meth_param_cc IS TABLE OF epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EPIS_ABCDE_METH"
    TYPE id_epis_abcde_meth_cc IS TABLE OF epis_abcde_meth_param.id_epis_abcde_meth%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PARAM"
    TYPE id_param_cc IS TABLE OF epis_abcde_meth_param.id_param%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_TYPE"
    TYPE flg_type_cc IS TABLE OF epis_abcde_meth_param.flg_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "PARAM_TEXT"
    TYPE param_text_cc IS TABLE OF epis_abcde_meth_param.param_text%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF epis_abcde_meth_param.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROF_CREATE"
    TYPE id_prof_create_cc IS TABLE OF epis_abcde_meth_param.id_prof_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_CREATE"
    TYPE dt_create_cc IS TABLE OF epis_abcde_meth_param.dt_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF epis_abcde_meth_param.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF epis_abcde_meth_param.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF epis_abcde_meth_param.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF epis_abcde_meth_param.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF epis_abcde_meth_param.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF epis_abcde_meth_param.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN epis_abcde_meth_param%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN epis_abcde_meth_param%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN epis_abcde_meth_param_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN epis_abcde_meth_param_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in           IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in           IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in         IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in         IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in     IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in          IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in        IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in           IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in           IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in         IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in         IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in     IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in          IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in        IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_epis_abcde_meth_in        IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                  IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                  IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in                IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in                IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in            IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                 IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in               IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in               IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in        IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in               IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in               IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in        IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        id_epis_abcde_meth_param_out IN OUT epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_epis_abcde_meth_in        IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                  IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                  IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in                IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in                IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in            IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                 IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in               IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in               IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in        IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in               IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in               IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in        IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        id_epis_abcde_meth_param_out IN OUT epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in           IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in           IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in         IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in         IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in     IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in          IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in        IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE;

    FUNCTION ins
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in           IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in           IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in         IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in         IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in     IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in          IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in        IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in        IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in        IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_epis_abcde_meth_nin      IN BOOLEAN := TRUE,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        id_param_nin                IN BOOLEAN := TRUE,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        param_text_nin              IN BOOLEAN := TRUE,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin          IN BOOLEAN := TRUE,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        dt_create_nin               IN BOOLEAN := TRUE,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_epis_abcde_meth_nin      IN BOOLEAN := TRUE,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        id_param_nin                IN BOOLEAN := TRUE,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        param_text_nin              IN BOOLEAN := TRUE,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin          IN BOOLEAN := TRUE,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        dt_create_nin               IN BOOLEAN := TRUE,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_epis_abcde_meth_in  IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_epis_abcde_meth_nin IN BOOLEAN := TRUE,
        id_param_in            IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        id_param_nin           IN BOOLEAN := TRUE,
        flg_type_in            IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        param_text_in          IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        param_text_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_epis_abcde_meth_in  IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_epis_abcde_meth_nin IN BOOLEAN := TRUE,
        id_param_in            IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        id_param_nin           IN BOOLEAN := TRUE,
        flg_type_in            IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        param_text_in          IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        param_text_nin         IN BOOLEAN := TRUE,
        flg_status_in          IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        id_prof_create_in      IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        id_prof_create_nin     IN BOOLEAN := TRUE,
        dt_create_in           IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        dt_create_nin          IN BOOLEAN := TRUE,
        create_user_in         IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        id_epis_abcde_meth_in       IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE DEFAULT NULL,
        id_param_in                 IN epis_abcde_meth_param.id_param%TYPE DEFAULT NULL,
        flg_type_in                 IN epis_abcde_meth_param.flg_type%TYPE DEFAULT NULL,
        param_text_in               IN epis_abcde_meth_param.param_text%TYPE DEFAULT NULL,
        flg_status_in               IN epis_abcde_meth_param.flg_status%TYPE DEFAULT NULL,
        id_prof_create_in           IN epis_abcde_meth_param.id_prof_create%TYPE DEFAULT NULL,
        dt_create_in                IN epis_abcde_meth_param.dt_create%TYPE DEFAULT NULL,
        create_user_in              IN epis_abcde_meth_param.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_abcde_meth_param.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_abcde_meth_param.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_abcde_meth_param.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_abcde_meth_param.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_abcde_meth_param.update_institution%TYPE DEFAULT NULL,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN epis_abcde_meth_param%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN epis_abcde_meth_param%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN epis_abcde_meth_param_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN epis_abcde_meth_param_tc,
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
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    -- Delete all rows for primary key column ID_EPIS_ABCDE_METH_PARAM
    PROCEDURE del_id_epis_abcde_meth_param
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_EPIS_ABCDE_METH_PARAM
    PROCEDURE del_id_epis_abcde_meth_param
    (
        id_epis_abcde_meth_param_in IN epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    OUT table_varchar
    );

    -- Delete all rows for this EAMHP_EAMH_FK foreign key value
    PROCEDURE del_eamhp_eamh_fk
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EAMHP_EAMH_FK foreign key value
    PROCEDURE del_eamhp_eamh_fk
    (
        id_epis_abcde_meth_in IN epis_abcde_meth_param.id_epis_abcde_meth%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this EAMHP_PROF_FK foreign key value
    PROCEDURE del_eamhp_prof_fk
    (
        id_prof_create_in IN epis_abcde_meth_param.id_prof_create%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EAMHP_PROF_FK foreign key value
    PROCEDURE del_eamhp_prof_fk
    (
        id_prof_create_in IN epis_abcde_meth_param.id_prof_create%TYPE,
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
    PROCEDURE initrec(epis_abcde_meth_param_inout IN OUT epis_abcde_meth_param%ROWTYPE);

    FUNCTION initrec RETURN epis_abcde_meth_param%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_abcde_meth_param_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_abcde_meth_param_tc;

END ts_epis_abcde_meth_param;
/
