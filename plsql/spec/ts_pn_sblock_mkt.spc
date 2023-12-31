/*-- Last Change Revision: $Rev: 1889001 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2019-01-28 17:25:16 +0000 (seg, 28 jan 2019) $*/
CREATE OR REPLACE PACKAGE ts_pn_sblock_mkt
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2019-01-21 11:46:35
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on pn_sblock_mkt
    TYPE pn_sblock_mkt_tc IS TABLE OF pn_sblock_mkt%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE pn_sblock_mkt_ntt IS TABLE OF pn_sblock_mkt%ROWTYPE;
    TYPE pn_sblock_mkt_vat IS VARRAY(100) OF pn_sblock_mkt%ROWTYPE;

    -- Column Collection based on column ID_PN_SOAP_BLOCK
    TYPE id_pn_soap_block_cc IS TABLE OF pn_sblock_mkt.id_pn_soap_block%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PN_NOTE_TYPE
    TYPE id_pn_note_type_cc IS TABLE OF pn_sblock_mkt.id_pn_note_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_SOFTWARE
    TYPE id_software_cc IS TABLE OF pn_sblock_mkt.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_MARKET
    TYPE id_market_cc IS TABLE OF pn_sblock_mkt.id_market%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column RANK
    TYPE rank_cc IS TABLE OF pn_sblock_mkt.rank%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF pn_sblock_mkt.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF pn_sblock_mkt.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF pn_sblock_mkt.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF pn_sblock_mkt.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF pn_sblock_mkt.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF pn_sblock_mkt.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_EXECUTE_IMPORT
    TYPE flg_execute_import_cc IS TABLE OF pn_sblock_mkt.flg_execute_import%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_SHOW_TITLE
    TYPE flg_show_title_cc IS TABLE OF pn_sblock_mkt.flg_show_title%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_SWF_FILE_VIEWER
    TYPE id_swf_file_viewer_cc IS TABLE OF pn_sblock_mkt.id_swf_file_viewer%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column VALUE_VIEWER
    TYPE value_viewer_cc IS TABLE OF pn_sblock_mkt.value_viewer%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column AGE_MIN
    TYPE age_min_cc IS TABLE OF pn_sblock_mkt.age_min%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column AGE_MAX
    TYPE age_max_cc IS TABLE OF pn_sblock_mkt.age_max%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_pn_soap_block_in   IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in    IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in        IN pn_sblock_mkt.id_software%TYPE,
        id_market_in          IN pn_sblock_mkt.id_market%TYPE,
        rank_in               IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        create_user_in        IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        flg_execute_import_in IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT 'N',
        flg_show_title_in     IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT 'Y',
        id_swf_file_viewer_in IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        value_viewer_in       IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        age_min_in            IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_max_in            IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_pn_soap_block_in   IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in    IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in        IN pn_sblock_mkt.id_software%TYPE,
        id_market_in          IN pn_sblock_mkt.id_market%TYPE,
        rank_in               IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        create_user_in        IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        flg_execute_import_in IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT 'N',
        flg_show_title_in     IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT 'Y',
        id_swf_file_viewer_in IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        value_viewer_in       IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        age_min_in            IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_max_in            IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN pn_sblock_mkt%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN pn_sblock_mkt%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN pn_sblock_mkt_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN pn_sblock_mkt_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_pn_soap_block_in    IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in     IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in         IN pn_sblock_mkt.id_software%TYPE,
        id_market_in           IN pn_sblock_mkt.id_market%TYPE,
        rank_in                IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        create_user_in         IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_execute_import_in  IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_execute_import_nin IN BOOLEAN := TRUE,
        flg_show_title_in      IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        flg_show_title_nin     IN BOOLEAN := TRUE,
        id_swf_file_viewer_in  IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        id_swf_file_viewer_nin IN BOOLEAN := TRUE,
        value_viewer_in        IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        value_viewer_nin       IN BOOLEAN := TRUE,
        age_min_in             IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_min_nin            IN BOOLEAN := TRUE,
        age_max_in             IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        age_max_nin            IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_pn_soap_block_in    IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in     IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in         IN pn_sblock_mkt.id_software%TYPE,
        id_market_in           IN pn_sblock_mkt.id_market%TYPE,
        rank_in                IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        create_user_in         IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_execute_import_in  IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_execute_import_nin IN BOOLEAN := TRUE,
        flg_show_title_in      IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        flg_show_title_nin     IN BOOLEAN := TRUE,
        id_swf_file_viewer_in  IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        id_swf_file_viewer_nin IN BOOLEAN := TRUE,
        value_viewer_in        IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        value_viewer_nin       IN BOOLEAN := TRUE,
        age_min_in             IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_min_nin            IN BOOLEAN := TRUE,
        age_max_in             IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        age_max_nin            IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        rank_in                IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        create_user_in         IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_execute_import_in  IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_execute_import_nin IN BOOLEAN := TRUE,
        flg_show_title_in      IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        flg_show_title_nin     IN BOOLEAN := TRUE,
        id_swf_file_viewer_in  IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        id_swf_file_viewer_nin IN BOOLEAN := TRUE,
        value_viewer_in        IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        value_viewer_nin       IN BOOLEAN := TRUE,
        age_min_in             IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_min_nin            IN BOOLEAN := TRUE,
        age_max_in             IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        age_max_nin            IN BOOLEAN := TRUE,
        where_in               IN VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        rank_in                IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        rank_nin               IN BOOLEAN := TRUE,
        create_user_in         IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        flg_execute_import_in  IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_execute_import_nin IN BOOLEAN := TRUE,
        flg_show_title_in      IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        flg_show_title_nin     IN BOOLEAN := TRUE,
        id_swf_file_viewer_in  IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        id_swf_file_viewer_nin IN BOOLEAN := TRUE,
        value_viewer_in        IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        value_viewer_nin       IN BOOLEAN := TRUE,
        age_min_in             IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_min_nin            IN BOOLEAN := TRUE,
        age_max_in             IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        age_max_nin            IN BOOLEAN := TRUE,
        where_in               IN VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_pn_soap_block_in   IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in    IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in        IN pn_sblock_mkt.id_software%TYPE,
        id_market_in          IN pn_sblock_mkt.id_market%TYPE,
        rank_in               IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        create_user_in        IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        flg_execute_import_in IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_show_title_in     IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        id_swf_file_viewer_in IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        value_viewer_in       IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        age_min_in            IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_max_in            IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_pn_soap_block_in   IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in    IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in        IN pn_sblock_mkt.id_software%TYPE,
        id_market_in          IN pn_sblock_mkt.id_market%TYPE,
        rank_in               IN pn_sblock_mkt.rank%TYPE DEFAULT NULL,
        create_user_in        IN pn_sblock_mkt.create_user%TYPE DEFAULT NULL,
        create_time_in        IN pn_sblock_mkt.create_time%TYPE DEFAULT NULL,
        create_institution_in IN pn_sblock_mkt.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN pn_sblock_mkt.update_user%TYPE DEFAULT NULL,
        update_time_in        IN pn_sblock_mkt.update_time%TYPE DEFAULT NULL,
        update_institution_in IN pn_sblock_mkt.update_institution%TYPE DEFAULT NULL,
        flg_execute_import_in IN pn_sblock_mkt.flg_execute_import%TYPE DEFAULT NULL,
        flg_show_title_in     IN pn_sblock_mkt.flg_show_title%TYPE DEFAULT NULL,
        id_swf_file_viewer_in IN pn_sblock_mkt.id_swf_file_viewer%TYPE DEFAULT NULL,
        value_viewer_in       IN pn_sblock_mkt.value_viewer%TYPE DEFAULT NULL,
        age_min_in            IN pn_sblock_mkt.age_min%TYPE DEFAULT NULL,
        age_max_in            IN pn_sblock_mkt.age_max%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN pn_sblock_mkt%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN pn_sblock_mkt%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN pn_sblock_mkt_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN pn_sblock_mkt_tc,
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
        id_pn_soap_block_in IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in  IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in      IN pn_sblock_mkt.id_software%TYPE,
        id_market_in        IN pn_sblock_mkt.id_market%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_pn_soap_block_in IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        id_pn_note_type_in  IN pn_sblock_mkt.id_pn_note_type%TYPE,
        id_software_in      IN pn_sblock_mkt.id_software%TYPE,
        id_market_in        IN pn_sblock_mkt.id_market%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
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

    -- Delete all rows for this PNSBM_PNNT_FK foreign key value
    PROCEDURE del_pnsbm_pnnt_fk
    (
        id_pn_note_type_in IN pn_sblock_mkt.id_pn_note_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this PSM_MRK_FK foreign key value
    PROCEDURE del_psm_mrk_fk
    (
        id_market_in    IN pn_sblock_mkt.id_market%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PSM_PNSB_FK foreign key value
    PROCEDURE del_psm_pnsb_fk
    (
        id_pn_soap_block_in IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE,
        rows_out            OUT table_varchar
    );

    -- Delete all rows for this PSM_S_FK foreign key value
    PROCEDURE del_psm_s_fk
    (
        id_software_in  IN pn_sblock_mkt.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this PNSBM_PNNT_FK foreign key value
    PROCEDURE del_pnsbm_pnnt_fk
    (
        id_pn_note_type_in IN pn_sblock_mkt.id_pn_note_type%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PSM_MRK_FK foreign key value
    PROCEDURE del_psm_mrk_fk
    (
        id_market_in    IN pn_sblock_mkt.id_market%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PSM_PNSB_FK foreign key value
    PROCEDURE del_psm_pnsb_fk
    (
        id_pn_soap_block_in IN pn_sblock_mkt.id_pn_soap_block%TYPE,
        handle_error_in     IN BOOLEAN := TRUE
    );

    -- Delete all rows for this PSM_S_FK foreign key value
    PROCEDURE del_psm_s_fk
    (
        id_software_in  IN pn_sblock_mkt.id_software%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(pn_sblock_mkt_inout IN OUT pn_sblock_mkt%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN pn_sblock_mkt%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN pn_sblock_mkt_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN pn_sblock_mkt_tc;

END ts_pn_sblock_mkt;
/
