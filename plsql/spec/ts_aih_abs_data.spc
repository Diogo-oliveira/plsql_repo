/*-- Last Change Revision: $Rev: 1797197 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2017-09-28 10:13:30 +0100 (qui, 28 set 2017) $*/
CREATE OR REPLACE PACKAGE ts_aih_abs_data
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2017-09-05 13:46:37
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on aih_abs_data
    TYPE aih_abs_data_tc IS TABLE OF aih_abs_data%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE aih_abs_data_ntt IS TABLE OF aih_abs_data%ROWTYPE;
    TYPE aih_abs_data_vat IS VARRAY(100) OF aih_abs_data%ROWTYPE;

    -- Column Collection based on column ID_AIH_ABS_DATA
    TYPE id_aih_abs_data_cc IS TABLE OF aih_abs_data.id_aih_abs_data%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_AIH_DATA
    TYPE id_aih_data_cc IS TABLE OF aih_abs_data.id_aih_data%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_AIH_TYPE
    TYPE flg_aih_type_cc IS TABLE OF aih_abs_data.flg_aih_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_FIELD_TYPE
    TYPE flg_field_type_cc IS TABLE OF aih_abs_data.flg_field_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAG
    TYPE id_diag_cc IS TABLE OF aih_abs_data.id_diag%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ALERT_DIAG
    TYPE id_alert_diag_cc IS TABLE OF aih_abs_data.id_alert_diag%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_DIAG_INST_OWNER
    TYPE id_diag_inst_owner_cc IS TABLE OF aih_abs_data.id_diag_inst_owner%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_ADIAG_INST_OWNER
    TYPE id_adiag_inst_owner_cc IS TABLE OF aih_abs_data.id_adiag_inst_owner%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DIAG_QUANTITY
    TYPE diag_quantity_cc IS TABLE OF aih_abs_data.diag_quantity%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ABS_ORDER
    TYPE abs_order_cc IS TABLE OF aih_abs_data.abs_order%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF aih_abs_data.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF aih_abs_data.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF aih_abs_data.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF aih_abs_data.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF aih_abs_data.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF aih_abs_data.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_aih_abs_data_in     IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_aih_abs_data_in     IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN aih_abs_data%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN aih_abs_data%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN aih_abs_data_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN aih_abs_data_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN aih_abs_data.id_aih_abs_data%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        id_aih_abs_data_out    IN OUT aih_abs_data.id_aih_abs_data%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        id_aih_abs_data_out    IN OUT aih_abs_data.id_aih_abs_data%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN aih_abs_data.id_aih_abs_data%TYPE;

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT 0,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN aih_abs_data.id_aih_abs_data%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_aih_abs_data_in      IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in          IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        id_aih_data_nin         IN BOOLEAN := TRUE,
        flg_aih_type_in         IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_aih_type_nin        IN BOOLEAN := TRUE,
        flg_field_type_in       IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        flg_field_type_nin      IN BOOLEAN := TRUE,
        id_diag_in              IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_diag_nin             IN BOOLEAN := TRUE,
        id_alert_diag_in        IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_alert_diag_nin       IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        diag_quantity_in        IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        diag_quantity_nin       IN BOOLEAN := TRUE,
        abs_order_in            IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        abs_order_nin           IN BOOLEAN := TRUE,
        create_user_in          IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_aih_abs_data_in      IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in          IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        id_aih_data_nin         IN BOOLEAN := TRUE,
        flg_aih_type_in         IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_aih_type_nin        IN BOOLEAN := TRUE,
        flg_field_type_in       IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        flg_field_type_nin      IN BOOLEAN := TRUE,
        id_diag_in              IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_diag_nin             IN BOOLEAN := TRUE,
        id_alert_diag_in        IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_alert_diag_nin       IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        diag_quantity_in        IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        diag_quantity_nin       IN BOOLEAN := TRUE,
        abs_order_in            IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        abs_order_nin           IN BOOLEAN := TRUE,
        create_user_in          IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_aih_data_in          IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        id_aih_data_nin         IN BOOLEAN := TRUE,
        flg_aih_type_in         IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_aih_type_nin        IN BOOLEAN := TRUE,
        flg_field_type_in       IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        flg_field_type_nin      IN BOOLEAN := TRUE,
        id_diag_in              IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_diag_nin             IN BOOLEAN := TRUE,
        id_alert_diag_in        IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_alert_diag_nin       IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        diag_quantity_in        IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        diag_quantity_nin       IN BOOLEAN := TRUE,
        abs_order_in            IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        abs_order_nin           IN BOOLEAN := TRUE,
        create_user_in          IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE,
        rows_out                IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_aih_data_in          IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        id_aih_data_nin         IN BOOLEAN := TRUE,
        flg_aih_type_in         IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_aih_type_nin        IN BOOLEAN := TRUE,
        flg_field_type_in       IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        flg_field_type_nin      IN BOOLEAN := TRUE,
        id_diag_in              IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_diag_nin             IN BOOLEAN := TRUE,
        id_alert_diag_in        IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_alert_diag_nin       IN BOOLEAN := TRUE,
        id_diag_inst_owner_in   IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_diag_inst_owner_nin  IN BOOLEAN := TRUE,
        id_adiag_inst_owner_in  IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_nin IN BOOLEAN := TRUE,
        diag_quantity_in        IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        diag_quantity_nin       IN BOOLEAN := TRUE,
        abs_order_in            IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        abs_order_nin           IN BOOLEAN := TRUE,
        create_user_in          IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_user_nin         IN BOOLEAN := TRUE,
        create_time_in          IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_time_nin         IN BOOLEAN := TRUE,
        create_institution_in   IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        create_institution_nin  IN BOOLEAN := TRUE,
        update_user_in          IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_user_nin         IN BOOLEAN := TRUE,
        update_time_in          IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_time_nin         IN BOOLEAN := TRUE,
        update_institution_in   IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        update_institution_nin  IN BOOLEAN := TRUE,
        where_in                IN VARCHAR2,
        handle_error_in         IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_aih_abs_data_in     IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_aih_abs_data_in     IN aih_abs_data.id_aih_abs_data%TYPE,
        id_aih_data_in         IN aih_abs_data.id_aih_data%TYPE DEFAULT NULL,
        flg_aih_type_in        IN aih_abs_data.flg_aih_type%TYPE DEFAULT NULL,
        flg_field_type_in      IN aih_abs_data.flg_field_type%TYPE DEFAULT NULL,
        id_diag_in             IN aih_abs_data.id_diag%TYPE DEFAULT NULL,
        id_alert_diag_in       IN aih_abs_data.id_alert_diag%TYPE DEFAULT NULL,
        id_diag_inst_owner_in  IN aih_abs_data.id_diag_inst_owner%TYPE DEFAULT NULL,
        id_adiag_inst_owner_in IN aih_abs_data.id_adiag_inst_owner%TYPE DEFAULT NULL,
        diag_quantity_in       IN aih_abs_data.diag_quantity%TYPE DEFAULT NULL,
        abs_order_in           IN aih_abs_data.abs_order%TYPE DEFAULT NULL,
        create_user_in         IN aih_abs_data.create_user%TYPE DEFAULT NULL,
        create_time_in         IN aih_abs_data.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN aih_abs_data.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN aih_abs_data.update_user%TYPE DEFAULT NULL,
        update_time_in         IN aih_abs_data.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN aih_abs_data.update_institution%TYPE DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN aih_abs_data%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN aih_abs_data%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN aih_abs_data_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN aih_abs_data_tc,
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
        id_aih_abs_data_in IN aih_abs_data.id_aih_abs_data%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_aih_abs_data_in IN aih_abs_data.id_aih_abs_data%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
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

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(aih_abs_data_inout IN OUT aih_abs_data%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN aih_abs_data%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN aih_abs_data_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN aih_abs_data_tc;

END ts_aih_abs_data;
/