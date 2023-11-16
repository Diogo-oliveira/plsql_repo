/*-- Last Change Revision: $Rev: 1683523 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2015-02-04 16:57:36 +0000 (qua, 04 fev 2015) $*/

CREATE OR REPLACE PACKAGE ts_vs_soft_inst
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Janeiro 22, 2015 10:46:44
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "VS_SOFT_INST"
    TYPE vs_soft_inst_tc IS TABLE OF vs_soft_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE vs_soft_inst_ntt IS TABLE OF vs_soft_inst%ROWTYPE;
    TYPE vs_soft_inst_vat IS VARRAY(100) OF vs_soft_inst%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF vs_soft_inst%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF vs_soft_inst%ROWTYPE;
    TYPE vat IS VARRAY(100) OF vs_soft_inst%ROWTYPE;

    -- Column Collection based on column "ID_VS_SOFT_INST"
    TYPE id_vs_soft_inst_cc IS TABLE OF vs_soft_inst.id_vs_soft_inst%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_VITAL_SIGN"
    TYPE id_vital_sign_cc IS TABLE OF vs_soft_inst.id_vital_sign%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_UNIT_MEASURE"
    TYPE id_unit_measure_cc IS TABLE OF vs_soft_inst.id_unit_measure%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF vs_soft_inst.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF vs_soft_inst.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "RANK"
    TYPE rank_cc IS TABLE OF vs_soft_inst.rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_VIEW"
    TYPE flg_view_cc IS TABLE OF vs_soft_inst.flg_view%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "COLOR_GRAFH"
    TYPE color_grafh_cc IS TABLE OF vs_soft_inst.color_grafh%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ADW_LAST_UPDATE"
    TYPE adw_last_update_cc IS TABLE OF vs_soft_inst.adw_last_update%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "COLOR_TEXT"
    TYPE color_text_cc IS TABLE OF vs_soft_inst.color_text%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "BOX_TYPE"
    TYPE box_type_cc IS TABLE OF vs_soft_inst.box_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF vs_soft_inst.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF vs_soft_inst.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF vs_soft_inst.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF vs_soft_inst.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF vs_soft_inst.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF vs_soft_inst.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_vs_soft_inst_in    IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in     IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in      IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_unit_measure_in    IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_software_in        IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        rank_in               IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        flg_view_in           IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        color_grafh_in        IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        adw_last_update_in    IN vs_soft_inst.adw_last_update%TYPE DEFAULT SYSDATE,
        color_text_in         IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        box_type_in           IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        create_user_in        IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN vs_soft_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_vs_soft_inst_in    IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in     IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in      IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_unit_measure_in    IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_software_in        IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        rank_in               IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        flg_view_in           IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        color_grafh_in        IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        adw_last_update_in    IN vs_soft_inst.adw_last_update%TYPE DEFAULT SYSDATE,
        color_text_in         IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        box_type_in           IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        create_user_in        IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN vs_soft_inst.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    PROCEDURE ins
    (
        rec_in          IN vs_soft_inst%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN vs_soft_inst%ROWTYPE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN vs_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN vs_soft_inst_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_vs_soft_inst_in     IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in      IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in       IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin      IN BOOLEAN := TRUE,
        id_unit_measure_in     IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin    IN BOOLEAN := TRUE,
        id_software_in         IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        rank_in                IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        flg_view_in            IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        flg_view_nin           IN BOOLEAN := TRUE,
        color_grafh_in         IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        color_grafh_nin        IN BOOLEAN := TRUE,
        adw_last_update_in     IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin    IN BOOLEAN := TRUE,
        color_text_in          IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        color_text_nin         IN BOOLEAN := TRUE,
        box_type_in            IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        box_type_nin           IN BOOLEAN := TRUE,
        create_user_in         IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vs_soft_inst_in     IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in      IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in       IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin      IN BOOLEAN := TRUE,
        id_unit_measure_in     IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin    IN BOOLEAN := TRUE,
        id_software_in         IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        rank_in                IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        flg_view_in            IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        flg_view_nin           IN BOOLEAN := TRUE,
        color_grafh_in         IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        color_grafh_nin        IN BOOLEAN := TRUE,
        adw_last_update_in     IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin    IN BOOLEAN := TRUE,
        color_text_in          IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        color_text_nin         IN BOOLEAN := TRUE,
        box_type_in            IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        box_type_nin           IN BOOLEAN := TRUE,
        create_user_in         IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_vital_sign_in       IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin      IN BOOLEAN := TRUE,
        id_unit_measure_in     IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin    IN BOOLEAN := TRUE,
        id_software_in         IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        rank_in                IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        flg_view_in            IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        flg_view_nin           IN BOOLEAN := TRUE,
        color_grafh_in         IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        color_grafh_nin        IN BOOLEAN := TRUE,
        adw_last_update_in     IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin    IN BOOLEAN := TRUE,
        color_text_in          IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        color_text_nin         IN BOOLEAN := TRUE,
        box_type_in            IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        box_type_nin           IN BOOLEAN := TRUE,
        create_user_in         IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_vital_sign_in       IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_vital_sign_nin      IN BOOLEAN := TRUE,
        id_unit_measure_in     IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_unit_measure_nin    IN BOOLEAN := TRUE,
        id_software_in         IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        rank_in                IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        flg_view_in            IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        flg_view_nin           IN BOOLEAN := TRUE,
        color_grafh_in         IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        color_grafh_nin        IN BOOLEAN := TRUE,
        adw_last_update_in     IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin    IN BOOLEAN := TRUE,
        color_text_in          IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        color_text_nin         IN BOOLEAN := TRUE,
        box_type_in            IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        box_type_nin           IN BOOLEAN := TRUE,
        create_user_in         IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_vs_soft_inst_in    IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in     IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in      IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_unit_measure_in    IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_software_in        IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        rank_in               IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        flg_view_in           IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        color_grafh_in        IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        adw_last_update_in    IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        color_text_in         IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        box_type_in           IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        create_user_in        IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_vs_soft_inst_in    IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in     IN vs_soft_inst.id_institution%TYPE,
        id_vital_sign_in      IN vs_soft_inst.id_vital_sign%TYPE DEFAULT NULL,
        id_unit_measure_in    IN vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL,
        id_software_in        IN vs_soft_inst.id_software%TYPE DEFAULT NULL,
        rank_in               IN vs_soft_inst.rank%TYPE DEFAULT NULL,
        flg_view_in           IN vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        color_grafh_in        IN vs_soft_inst.color_grafh%TYPE DEFAULT NULL,
        adw_last_update_in    IN vs_soft_inst.adw_last_update%TYPE DEFAULT NULL,
        color_text_in         IN vs_soft_inst.color_text%TYPE DEFAULT NULL,
        box_type_in           IN vs_soft_inst.box_type%TYPE DEFAULT NULL,
        create_user_in        IN vs_soft_inst.create_user%TYPE DEFAULT NULL,
        create_time_in        IN vs_soft_inst.create_time%TYPE DEFAULT NULL,
        create_institution_in IN vs_soft_inst.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN vs_soft_inst.update_user%TYPE DEFAULT NULL,
        update_time_in        IN vs_soft_inst.update_time%TYPE DEFAULT NULL,
        update_institution_in IN vs_soft_inst.update_institution%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN vs_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN vs_soft_inst%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN vs_soft_inst_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN vs_soft_inst_tc,
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
        id_vs_soft_inst_in IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in  IN vs_soft_inst.id_institution%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_vs_soft_inst_in IN vs_soft_inst.id_vs_soft_inst%TYPE,
        id_institution_in  IN vs_soft_inst.id_institution%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for primary key column ID_VS_SOFT_INST
    PROCEDURE del_id_vs_soft_inst
    (
        id_vs_soft_inst_in IN vs_soft_inst.id_vs_soft_inst%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_VS_SOFT_INST
    PROCEDURE del_id_vs_soft_inst
    (
        id_vs_soft_inst_in IN vs_soft_inst.id_vs_soft_inst%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN vs_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_INSTITUTION
    PROCEDURE del_id_institution
    (
        id_institution_in IN vs_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this VSSI_INST_FK foreign key value
    PROCEDURE del_vssi_inst_fk
    (
        id_institution_in IN vs_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this VSSI_INST_FK foreign key value
    PROCEDURE del_vssi_inst_fk
    (
        id_institution_in IN vs_soft_inst.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this VSSI_S_FK foreign key value
    PROCEDURE del_vssi_s_fk
    (
        id_software_in  IN vs_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this VSSI_S_FK foreign key value
    PROCEDURE del_vssi_s_fk
    (
        id_software_in  IN vs_soft_inst.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this VSSI_UNITM_FK foreign key value
    PROCEDURE del_vssi_unitm_fk
    (
        id_unit_measure_in IN vs_soft_inst.id_unit_measure%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this VSSI_UNITM_FK foreign key value
    PROCEDURE del_vssi_unitm_fk
    (
        id_unit_measure_in IN vs_soft_inst.id_unit_measure%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this VSSI_VSN_FK foreign key value
    PROCEDURE del_vssi_vsn_fk
    (
        id_vital_sign_in IN vs_soft_inst.id_vital_sign%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Delete all rows for this VSSI_VSN_FK foreign key value
    PROCEDURE del_vssi_vsn_fk
    (
        id_vital_sign_in IN vs_soft_inst.id_vital_sign%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
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
    PROCEDURE initrec(vs_soft_inst_inout IN OUT vs_soft_inst%ROWTYPE);

    FUNCTION initrec RETURN vs_soft_inst%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN vs_soft_inst_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN vs_soft_inst_tc;

END ts_vs_soft_inst;
/