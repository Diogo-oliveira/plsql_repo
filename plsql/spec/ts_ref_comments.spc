/*-- Last Change Revision: $Rev: 1528861 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2013-11-27 10:48:36 +0000 (qua, 27 nov 2013) $*/
CREATE OR REPLACE PACKAGE ts_ref_comments
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: October 25, 2013 10:4:21
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on "REF_COMMENTS"
    TYPE ref_comments_tc IS TABLE OF ref_comments%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ref_comments_ntt IS TABLE OF ref_comments%ROWTYPE;
    TYPE ref_comments_vat IS VARRAY(100) OF ref_comments%ROWTYPE;

    -- Same type structure, with a static name.
    TYPE aat IS TABLE OF ref_comments%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ntt IS TABLE OF ref_comments%ROWTYPE;
    TYPE vat IS VARRAY(100) OF ref_comments%ROWTYPE;

    -- Column Collection based on column "ID_REF_COMMENT"
    TYPE id_ref_comment_cc IS TABLE OF ref_comments.id_ref_comment%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_EXTERNAL_REQUEST"
    TYPE id_external_request_cc IS TABLE OF ref_comments.id_external_request%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_TYPE"
    TYPE flg_type_cc IS TABLE OF ref_comments.flg_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_PROFESSIONAL"
    TYPE id_professional_cc IS TABLE OF ref_comments.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION"
    TYPE id_institution_cc IS TABLE OF ref_comments.id_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_SOFTWARE"
    TYPE id_software_cc IS TABLE OF ref_comments.id_software%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "FLG_STATUS"
    TYPE flg_status_cc IS TABLE OF ref_comments.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_COMMENT"
    TYPE dt_comment_cc IS TABLE OF ref_comments.dt_comment%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_COMMENT_CANCELED"
    TYPE dt_comment_canceled_cc IS TABLE OF ref_comments.dt_comment_canceled%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION_CANCELED"
    TYPE id_institution_canceled_cc IS TABLE OF ref_comments.id_institution_canceled%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "DT_COMMENT_OUTDATED"
    TYPE dt_comment_outdated_cc IS TABLE OF ref_comments.dt_comment_outdated%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "ID_INSTITUTION_OUTDATED"
    TYPE id_institution_outdated_cc IS TABLE OF ref_comments.id_institution_outdated%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_USER"
    TYPE create_user_cc IS TABLE OF ref_comments.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_TIME"
    TYPE create_time_cc IS TABLE OF ref_comments.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "CREATE_INSTITUTION"
    TYPE create_institution_cc IS TABLE OF ref_comments.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_USER"
    TYPE update_user_cc IS TABLE OF ref_comments.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_TIME"
    TYPE update_time_cc IS TABLE OF ref_comments.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column "UPDATE_INSTITUTION"
    TYPE update_institution_cc IS TABLE OF ref_comments.update_institution%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present
    PROCEDURE ins
    (
        id_ref_comment_in          IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_ref_comment_in          IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record.
    -- Specify whether or not a primary key value should be generated.
    PROCEDURE ins
    (
        rec_in          IN ref_comments%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rec_in          IN ref_comments%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers.
    PROCEDURE ins
    (
        rows_in         IN ref_comments_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        rows_in         IN ref_comments_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence.
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN ref_comments.id_ref_comment%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL,
        id_ref_comment_out         IN OUT ref_comments.id_ref_comment%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    PROCEDURE ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL,
        id_ref_comment_out         IN OUT ref_comments.id_ref_comment%TYPE
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN ref_comments.id_ref_comment%TYPE;

    FUNCTION ins
    (
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL
        -- Pass false if you want errors to propagate out unhandled
       ,
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN ref_comments.id_ref_comment%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.

    PROCEDURE upd
    (
        id_ref_comment_in           IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in      IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        id_external_request_nin     IN BOOLEAN := TRUE,
        flg_type_in                 IN ref_comments.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        id_professional_in          IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_professional_nin         IN BOOLEAN := TRUE,
        id_institution_in           IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_institution_nin          IN BOOLEAN := TRUE,
        id_software_in              IN ref_comments.id_software%TYPE DEFAULT NULL,
        id_software_nin             IN BOOLEAN := TRUE,
        flg_status_in               IN ref_comments.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        dt_comment_in               IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_nin              IN BOOLEAN := TRUE,
        dt_comment_canceled_in      IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        dt_comment_canceled_nin     IN BOOLEAN := TRUE,
        id_institution_canceled_in  IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_nin IN BOOLEAN := TRUE,
        dt_comment_outdated_in      IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        dt_comment_outdated_nin     IN BOOLEAN := TRUE,
        id_institution_outdated_in  IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_nin IN BOOLEAN := TRUE,
        create_user_in              IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN ref_comments.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN ref_comments.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_ref_comment_in           IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in      IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        id_external_request_nin     IN BOOLEAN := TRUE,
        flg_type_in                 IN ref_comments.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        id_professional_in          IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_professional_nin         IN BOOLEAN := TRUE,
        id_institution_in           IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_institution_nin          IN BOOLEAN := TRUE,
        id_software_in              IN ref_comments.id_software%TYPE DEFAULT NULL,
        id_software_nin             IN BOOLEAN := TRUE,
        flg_status_in               IN ref_comments.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        dt_comment_in               IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_nin              IN BOOLEAN := TRUE,
        dt_comment_canceled_in      IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        dt_comment_canceled_nin     IN BOOLEAN := TRUE,
        id_institution_canceled_in  IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_nin IN BOOLEAN := TRUE,
        dt_comment_outdated_in      IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        dt_comment_outdated_nin     IN BOOLEAN := TRUE,
        id_institution_outdated_in  IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_nin IN BOOLEAN := TRUE,
        create_user_in              IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN ref_comments.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN ref_comments.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        id_external_request_in      IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        id_external_request_nin     IN BOOLEAN := TRUE,
        flg_type_in                 IN ref_comments.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        id_professional_in          IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_professional_nin         IN BOOLEAN := TRUE,
        id_institution_in           IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_institution_nin          IN BOOLEAN := TRUE,
        id_software_in              IN ref_comments.id_software%TYPE DEFAULT NULL,
        id_software_nin             IN BOOLEAN := TRUE,
        flg_status_in               IN ref_comments.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        dt_comment_in               IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_nin              IN BOOLEAN := TRUE,
        dt_comment_canceled_in      IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        dt_comment_canceled_nin     IN BOOLEAN := TRUE,
        id_institution_canceled_in  IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_nin IN BOOLEAN := TRUE,
        dt_comment_outdated_in      IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        dt_comment_outdated_nin     IN BOOLEAN := TRUE,
        id_institution_outdated_in  IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_nin IN BOOLEAN := TRUE,
        create_user_in              IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN ref_comments.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN ref_comments.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        where_in                    VARCHAR2,
        handle_error_in             IN BOOLEAN := TRUE,
        rows_out                    IN OUT table_varchar
    );

    PROCEDURE upd
    (
        id_external_request_in      IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        id_external_request_nin     IN BOOLEAN := TRUE,
        flg_type_in                 IN ref_comments.flg_type%TYPE DEFAULT NULL,
        flg_type_nin                IN BOOLEAN := TRUE,
        id_professional_in          IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_professional_nin         IN BOOLEAN := TRUE,
        id_institution_in           IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_institution_nin          IN BOOLEAN := TRUE,
        id_software_in              IN ref_comments.id_software%TYPE DEFAULT NULL,
        id_software_nin             IN BOOLEAN := TRUE,
        flg_status_in               IN ref_comments.flg_status%TYPE DEFAULT NULL,
        flg_status_nin              IN BOOLEAN := TRUE,
        dt_comment_in               IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_nin              IN BOOLEAN := TRUE,
        dt_comment_canceled_in      IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        dt_comment_canceled_nin     IN BOOLEAN := TRUE,
        id_institution_canceled_in  IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_nin IN BOOLEAN := TRUE,
        dt_comment_outdated_in      IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        dt_comment_outdated_nin     IN BOOLEAN := TRUE,
        id_institution_outdated_in  IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_nin IN BOOLEAN := TRUE,
        create_user_in              IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_user_nin             IN BOOLEAN := TRUE,
        create_time_in              IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_time_nin             IN BOOLEAN := TRUE,
        create_institution_in       IN ref_comments.create_institution%TYPE DEFAULT NULL,
        create_institution_nin      IN BOOLEAN := TRUE,
        update_user_in              IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_user_nin             IN BOOLEAN := TRUE,
        update_time_in              IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_time_nin             IN BOOLEAN := TRUE,
        update_institution_in       IN ref_comments.update_institution%TYPE DEFAULT NULL,
        update_institution_nin      IN BOOLEAN := TRUE,
        where_in                    VARCHAR2,
        handle_error_in             IN BOOLEAN := TRUE
    );

    PROCEDURE upd_ins
    (
        id_ref_comment_in          IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    PROCEDURE upd_ins
    (
        id_ref_comment_in          IN ref_comments.id_ref_comment%TYPE,
        id_external_request_in     IN ref_comments.id_external_request%TYPE DEFAULT NULL,
        flg_type_in                IN ref_comments.flg_type%TYPE DEFAULT NULL,
        id_professional_in         IN ref_comments.id_professional%TYPE DEFAULT NULL,
        id_institution_in          IN ref_comments.id_institution%TYPE DEFAULT NULL,
        id_software_in             IN ref_comments.id_software%TYPE DEFAULT NULL,
        flg_status_in              IN ref_comments.flg_status%TYPE DEFAULT NULL,
        dt_comment_in              IN ref_comments.dt_comment%TYPE DEFAULT NULL,
        dt_comment_canceled_in     IN ref_comments.dt_comment_canceled%TYPE DEFAULT NULL,
        id_institution_canceled_in IN ref_comments.id_institution_canceled%TYPE DEFAULT NULL,
        dt_comment_outdated_in     IN ref_comments.dt_comment_outdated%TYPE DEFAULT NULL,
        id_institution_outdated_in IN ref_comments.id_institution_outdated%TYPE DEFAULT NULL,
        create_user_in             IN ref_comments.create_user%TYPE DEFAULT NULL,
        create_time_in             IN ref_comments.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN ref_comments.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN ref_comments.update_user%TYPE DEFAULT NULL,
        update_time_in             IN ref_comments.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN ref_comments.update_institution%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        rec_in          IN ref_comments%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    PROCEDURE upd
    (
        rec_in          IN ref_comments%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    PROCEDURE upd
    (
        col_in            IN ref_comments_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    PROCEDURE upd
    (
        col_in            IN ref_comments_tc,
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
        id_ref_comment_in IN ref_comments.id_ref_comment%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_ref_comment_in IN ref_comments.id_ref_comment%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for primary key column ID_REF_COMMENT
    PROCEDURE del_id_ref_comment
    (
        id_ref_comment_in IN ref_comments.id_ref_comment%TYPE,
        handle_error_in   IN BOOLEAN := TRUE
    );

    -- Delete all rows for primary key column ID_REF_COMMENT
    PROCEDURE del_id_ref_comment
    (
        id_ref_comment_in IN ref_comments.id_ref_comment%TYPE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          OUT table_varchar
    );

    -- Delete all rows for this RCS_PERT_FK foreign key value
    PROCEDURE del_rcs_pert_fk
    (
        id_external_request_in IN ref_comments.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RCS_PERT_FK foreign key value
    PROCEDURE del_rcs_pert_fk
    (
        id_external_request_in IN ref_comments.id_external_request%TYPE,
        handle_error_in        IN BOOLEAN := TRUE,
        rows_out               OUT table_varchar
    );

    -- Delete all rows for this RCS_PL_FK foreign key value
    PROCEDURE del_rcs_pl_fk
    (
        id_professional_in IN ref_comments.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this RCS_PL_FK foreign key value
    PROCEDURE del_rcs_pl_fk
    (
        id_professional_in IN ref_comments.id_professional%TYPE,
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
    PROCEDURE initrec(ref_comments_inout IN OUT ref_comments%ROWTYPE);

    FUNCTION initrec RETURN ref_comments%ROWTYPE;

    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN ref_comments_tc;

    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN ref_comments_tc;

END ts_ref_comments;
/
