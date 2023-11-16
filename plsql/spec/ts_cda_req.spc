/*-- Last Change Revision: $Rev: 1589205 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2014-05-13 12:47:15 +0100 (ter, 13 mai 2014) $*/
CREATE OR REPLACE PACKAGE ts_cda_req
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 5, 2014 11:2:37
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "CDA_REQ"
    TYPE cda_req_tc IS TABLE OF cda_req%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE cda_req_ntt IS TABLE OF cda_req%ROWTYPE;
    TYPE cda_req_vat IS VARRAY(100) OF cda_req%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF cda_req%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF cda_req%ROWTYPE;
    TYPE vat IS VARRAY(100) OF cda_req%ROWTYPE;

    -- Column Collection based on column "ID_CDA_REQ"
    TYPE id_cda_req_cc IS TABLE OF cda_req.id_cda_req%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF cda_req.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF cda_req.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_TYPE"
    TYPE flg_type_cc IS TABLE OF cda_req.flg_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_START"
    TYPE dt_start_cc IS TABLE OF cda_req.dt_start%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_END"
    TYPE dt_end_cc IS TABLE OF cda_req.dt_end%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF cda_req.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF cda_req.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF cda_req.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF cda_req.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF cda_req.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF cda_req.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_RANGE_START"
    TYPE dt_range_start_cc IS TABLE OF cda_req.dt_range_start%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_RANGE_END"
    TYPE dt_range_end_cc IS TABLE OF cda_req.dt_range_end%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CDA_REPORT_FILE"
    TYPE cda_report_file_cc IS TABLE OF cda_req.cda_report_file%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF cda_req.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF cda_req.id_software%TYPE INDEX BY BINARY_INTEGER;

    TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
    /*
    START Special logic for handling LOB columns....
    */
    PROCEDURE n_ins_clobs_in_chunks
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    PROCEDURE n_upd_clobs_in_chunks
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        ignore_if_null_in     IN BOOLEAN := TRUE,
        handle_error_in       IN BOOLEAN := TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    PROCEDURE n_upd_ins_clobs_in_chunks
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        ignore_if_null_in     IN BOOLEAN DEFAULT TRUE,
        handle_error_in       IN BOOLEAN DEFAULT TRUE,
        clob_columns_in       IN varchar2_t,
        clob_pieces_in        IN varchar2_t
    );

    /*
    END Special logic for handling LOB columns.
    */
    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN cda_req%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN cda_req%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN cda_req_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN cda_req_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN cda_req.id_cda_req%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        id_cda_req_out        IN OUT cda_req.id_cda_req%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        id_cda_req_out        IN OUT cda_req.id_cda_req%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN cda_req.id_cda_req%TYPE;

    FUNCTION ins
    (
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT current_timestamp,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN cda_req.id_cda_req%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_cda_req_in          IN cda_req.id_cda_req%TYPE,
        id_institution_in      IN cda_req.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_status_in          IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        flg_type_in            IN cda_req.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        dt_start_in            IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_start_nin           IN BOOLEAN := TRUE,
        dt_end_in              IN cda_req.dt_end%TYPE DEFAULT NULL,
        dt_end_nin             IN BOOLEAN := TRUE,
        create_user_in         IN cda_req.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN cda_req.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN cda_req.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN cda_req.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN cda_req.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN cda_req.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_range_start_in      IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_start_nin     IN BOOLEAN := TRUE,
        dt_range_end_in        IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        dt_range_end_nin       IN BOOLEAN := TRUE,
        cda_report_file_in     IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        cda_report_file_nin    IN BOOLEAN := TRUE,
        id_professional_in     IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_software_in         IN cda_req.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_cda_req_in          IN cda_req.id_cda_req%TYPE,
        id_institution_in      IN cda_req.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_status_in          IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        flg_type_in            IN cda_req.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        dt_start_in            IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_start_nin           IN BOOLEAN := TRUE,
        dt_end_in              IN cda_req.dt_end%TYPE DEFAULT NULL,
        dt_end_nin             IN BOOLEAN := TRUE,
        create_user_in         IN cda_req.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN cda_req.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN cda_req.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN cda_req.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN cda_req.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN cda_req.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_range_start_in      IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_start_nin     IN BOOLEAN := TRUE,
        dt_range_end_in        IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        dt_range_end_nin       IN BOOLEAN := TRUE,
        cda_report_file_in     IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        cda_report_file_nin    IN BOOLEAN := TRUE,
        id_professional_in     IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_software_in         IN cda_req.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_institution_in      IN cda_req.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_status_in          IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        flg_type_in            IN cda_req.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        dt_start_in            IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_start_nin           IN BOOLEAN := TRUE,
        dt_end_in              IN cda_req.dt_end%TYPE DEFAULT NULL,
        dt_end_nin             IN BOOLEAN := TRUE,
        create_user_in         IN cda_req.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN cda_req.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN cda_req.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN cda_req.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN cda_req.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN cda_req.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_range_start_in      IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_start_nin     IN BOOLEAN := TRUE,
        dt_range_end_in        IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        dt_range_end_nin       IN BOOLEAN := TRUE,
        cda_report_file_in     IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        cda_report_file_nin    IN BOOLEAN := TRUE,
        id_professional_in     IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_software_in         IN cda_req.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_institution_in      IN cda_req.id_institution%TYPE DEFAULT NULL,
        id_institution_nin     IN BOOLEAN := TRUE,
        flg_status_in          IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_status_nin         IN BOOLEAN := TRUE,
        flg_type_in            IN cda_req.flg_type%TYPE DEFAULT NULL,
        flg_type_nin           IN BOOLEAN := TRUE,
        dt_start_in            IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_start_nin           IN BOOLEAN := TRUE,
        dt_end_in              IN cda_req.dt_end%TYPE DEFAULT NULL,
        dt_end_nin             IN BOOLEAN := TRUE,
        create_user_in         IN cda_req.create_user%TYPE DEFAULT NULL,
        create_user_nin        IN BOOLEAN := TRUE,
        create_time_in         IN cda_req.create_time%TYPE DEFAULT NULL,
        create_time_nin        IN BOOLEAN := TRUE,
        create_institution_in  IN cda_req.create_institution%TYPE DEFAULT NULL,
        create_institution_nin IN BOOLEAN := TRUE,
        update_user_in         IN cda_req.update_user%TYPE DEFAULT NULL,
        update_user_nin        IN BOOLEAN := TRUE,
        update_time_in         IN cda_req.update_time%TYPE DEFAULT NULL,
        update_time_nin        IN BOOLEAN := TRUE,
        update_institution_in  IN cda_req.update_institution%TYPE DEFAULT NULL,
        update_institution_nin IN BOOLEAN := TRUE,
        dt_range_start_in      IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_start_nin     IN BOOLEAN := TRUE,
        dt_range_end_in        IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        dt_range_end_nin       IN BOOLEAN := TRUE,
        cda_report_file_in     IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        cda_report_file_nin    IN BOOLEAN := TRUE,
        id_professional_in     IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_professional_nin    IN BOOLEAN := TRUE,
        id_software_in         IN cda_req.id_software%TYPE DEFAULT NULL,
        id_software_nin        IN BOOLEAN := TRUE,
        where_in               VARCHAR2,
        handle_error_in        IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE,
        rows_out              OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_cda_req_in         IN cda_req.id_cda_req%TYPE,
        id_institution_in     IN cda_req.id_institution%TYPE DEFAULT NULL,
        flg_status_in         IN cda_req.flg_status%TYPE DEFAULT NULL,
        flg_type_in           IN cda_req.flg_type%TYPE DEFAULT NULL,
        dt_start_in           IN cda_req.dt_start%TYPE DEFAULT NULL,
        dt_end_in             IN cda_req.dt_end%TYPE DEFAULT NULL,
        create_user_in        IN cda_req.create_user%TYPE DEFAULT NULL,
        create_time_in        IN cda_req.create_time%TYPE DEFAULT NULL,
        create_institution_in IN cda_req.create_institution%TYPE DEFAULT NULL,
        update_user_in        IN cda_req.update_user%TYPE DEFAULT NULL,
        update_time_in        IN cda_req.update_time%TYPE DEFAULT NULL,
        update_institution_in IN cda_req.update_institution%TYPE DEFAULT NULL,
        dt_range_start_in     IN cda_req.dt_range_start%TYPE DEFAULT NULL,
        dt_range_end_in       IN cda_req.dt_range_end%TYPE DEFAULT NULL,
        cda_report_file_in    IN cda_req.cda_report_file%TYPE DEFAULT NULL,
        id_professional_in    IN cda_req.id_professional%TYPE DEFAULT NULL,
        id_software_in        IN cda_req.id_software%TYPE DEFAULT NULL,
        handle_error_in       IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN cda_req%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN cda_req%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN cda_req_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN cda_req_tc,
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
        id_cda_req_in   IN cda_req.id_cda_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_cda_req_in   IN cda_req.id_cda_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for primary key column ID_CDA_REQ
    PROCEDURE del_id_cda_req
    (
        id_cda_req_in   IN cda_req.id_cda_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_CDA_REQ
    PROCEDURE del_id_cda_req
    (
        id_cda_req_in   IN cda_req.id_cda_req%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this CDAR_INST_FK foreign key value
    PROCEDURE del_cdar_inst_fk
    (
        id_institution_in IN cda_req.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for this CDAR_INST_FK foreign key value
    PROCEDURE del_cdar_inst_fk
    (
        id_institution_in IN cda_req.id_institution%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this CDAR_PROF_FK foreign key value
    PROCEDURE del_cdar_prof_fk
    (
        id_professional_in IN cda_req.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this CDAR_PROF_FK foreign key value
    PROCEDURE del_cdar_prof_fk
    (
        id_professional_in IN cda_req.id_professional%TYPE,
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
    PROCEDURE initrec(cda_req_inout IN OUT cda_req%ROWTYPE);

    FUNCTION initrec RETURN cda_req%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN cda_req_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN cda_req_tc;

END ts_cda_req;
/
