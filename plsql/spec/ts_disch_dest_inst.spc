/*-- Last Change Revision: $Rev: 450898 $*/
/*-- Last Change by: $Author: pedro.teixeira $*/
/*-- Date of last change: $Date: 2010-03-25 09:53:25 +0000 (qui, 25 mar 2010) $*/

CREATE OR REPLACE PACKAGE ts_disch_dest_inst
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Mar�o 24, 2010 17:30:2
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "DISCH_DEST_INST"
    TYPE disch_dest_inst_tc IS TABLE OF disch_dest_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE disch_dest_inst_ntt IS TABLE OF disch_dest_inst%ROWTYPE;
    TYPE disch_dest_inst_vat IS VARRAY(100) OF disch_dest_inst%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF disch_dest_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF disch_dest_inst%ROWTYPE;
    TYPE vat IS VARRAY(100) OF disch_dest_inst%ROWTYPE;

    -- Column Collection based on column "ID_DISCH_DEST_INST"
    TYPE id_disch_dest_inst_cc IS TABLE OF disch_dest_inst.id_disch_dest_inst%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_DISCHARGE_DEST"
    TYPE id_discharge_dest_cc IS TABLE OF disch_dest_inst.id_discharge_dest%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION_EXT"
    TYPE id_institution_ext_cc IS TABLE OF disch_dest_inst.id_institution_ext%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF disch_dest_inst.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF disch_dest_inst.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_ACTIVE"
    TYPE flg_active_cc IS TABLE OF disch_dest_inst.flg_active%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF disch_dest_inst.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF disch_dest_inst.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF disch_dest_inst.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF disch_dest_inst.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF disch_dest_inst.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF disch_dest_inst.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN disch_dest_inst%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN disch_dest_inst%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN disch_dest_inst_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN disch_dest_inst_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN disch_dest_inst.id_disch_dest_inst%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        id_disch_dest_inst_out IN OUT disch_dest_inst.id_disch_dest_inst%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        id_disch_dest_inst_out IN OUT disch_dest_inst.id_disch_dest_inst%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN disch_dest_inst.id_disch_dest_inst%TYPE;

    FUNCTION ins
    (
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN disch_dest_inst.id_disch_dest_inst%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_disch_dest_inst_in  IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_discharge_dest_nin  IN BOOLEAN := TRUE,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_institution_ext_nin IN BOOLEAN := TRUE,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        flg_active_nin         IN BOOLEAN := TRUE,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_disch_dest_inst_in  IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_discharge_dest_nin  IN BOOLEAN := TRUE,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_institution_ext_nin IN BOOLEAN := TRUE,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        flg_active_nin         IN BOOLEAN := TRUE,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_discharge_dest_nin  IN BOOLEAN := TRUE,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_institution_ext_nin IN BOOLEAN := TRUE,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        flg_active_nin         IN BOOLEAN := TRUE,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_discharge_dest_in   IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_discharge_dest_nin  IN BOOLEAN := TRUE,
        id_institution_ext_in  IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_institution_ext_nin IN BOOLEAN := TRUE,
        id_software_in         IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        id_institution_in      IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_active_in          IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        flg_active_nin         IN BOOLEAN := TRUE,
        create_user_in         IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2 DEFAULT NULL,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE DEFAULT NULL,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE DEFAULT NULL,
        id_software_in        IN disch_dest_inst.id_software%TYPE DEFAULT NULL,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE DEFAULT NULL,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE DEFAULT NULL,
        create_user_in        IN disch_dest_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN disch_dest_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN disch_dest_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN disch_dest_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN disch_dest_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN disch_dest_inst.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN disch_dest_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN disch_dest_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN disch_dest_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN disch_dest_inst_tc,
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
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for primary key column ID_DISCH_DEST_INST
    PROCEDURE del_id_disch_dest_inst
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_DISCH_DEST_INST
    PROCEDURE del_id_disch_dest_inst
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete for unique value of DDI_UNIQUE_IDX1
    PROCEDURE del_ddi_unique_idx1
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE,
        id_software_in        IN disch_dest_inst.id_software%TYPE,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete for unique value of DDI_UNIQUE_IDX1
    PROCEDURE del_ddi_unique_idx1
    (
        id_disch_dest_inst_in IN disch_dest_inst.id_disch_dest_inst%TYPE,
        id_discharge_dest_in  IN disch_dest_inst.id_discharge_dest%TYPE,
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE,
        id_software_in        IN disch_dest_inst.id_software%TYPE,
        id_institution_in     IN disch_dest_inst.id_institution%TYPE,
        flg_active_in         IN disch_dest_inst.flg_active%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Delete all rows for this DDI_DISCH_DEST_FK foreign key value
    PROCEDURE del_ddi_disch_dest_fk
    (
        id_discharge_dest_in IN disch_dest_inst.id_discharge_dest%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for this DDI_DISCH_DEST_FK foreign key value
    PROCEDURE del_ddi_disch_dest_fk
    (
        id_discharge_dest_in IN disch_dest_inst.id_discharge_dest%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this DDI_INST_EXT_FK foreign key value
    PROCEDURE del_ddi_inst_ext_fk
    (
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Delete all rows for this DDI_INST_EXT_FK foreign key value
    PROCEDURE del_ddi_inst_ext_fk
    (
        id_institution_ext_in IN disch_dest_inst.id_institution_ext%TYPE,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
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
    PROCEDURE initrec(disch_dest_inst_inout IN OUT disch_dest_inst%ROWTYPE);

    FUNCTION initrec RETURN disch_dest_inst%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN disch_dest_inst_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN disch_dest_inst_tc;

END ts_disch_dest_inst;
/
