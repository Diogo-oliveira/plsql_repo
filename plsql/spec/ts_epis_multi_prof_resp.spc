CREATE OR REPLACE PACKAGE ts_epis_multi_prof_resp
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2018-01-15 10:30:54
| Created By: ALERT
*/
 IS

    -- Collection of %ROWTYPE records based on epis_multi_prof_resp
    TYPE epis_multi_prof_resp_tc IS TABLE OF epis_multi_prof_resp%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE epis_multi_prof_resp_ntt IS TABLE OF epis_multi_prof_resp%ROWTYPE;
    TYPE epis_multi_prof_resp_vat IS VARRAY(100) OF epis_multi_prof_resp%ROWTYPE;

    -- Column Collection based on column ID_EPIS_MULTI_PROF_RESP
    TYPE id_epis_multi_prof_resp_cc IS TABLE OF epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_EPISODE
    TYPE id_episode_cc IS TABLE OF epis_multi_prof_resp.id_episode%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_STATUS
    TYPE flg_status_cc IS TABLE OF epis_multi_prof_resp.flg_status%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_PROFESSIONAL
    TYPE id_professional_cc IS TABLE OF epis_multi_prof_resp.id_professional%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_PROFILE
    TYPE flg_profile_cc IS TABLE OF epis_multi_prof_resp.flg_profile%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_CREATE
    TYPE dt_create_cc IS TABLE OF epis_multi_prof_resp.dt_create%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_EPIS_PROF_RESP
    TYPE id_epis_prof_resp_cc IS TABLE OF epis_multi_prof_resp.id_epis_prof_resp%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_USER
    TYPE create_user_cc IS TABLE OF epis_multi_prof_resp.create_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_TIME
    TYPE create_time_cc IS TABLE OF epis_multi_prof_resp.create_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column CREATE_INSTITUTION
    TYPE create_institution_cc IS TABLE OF epis_multi_prof_resp.create_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_USER
    TYPE update_user_cc IS TABLE OF epis_multi_prof_resp.update_user%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_TIME
    TYPE update_time_cc IS TABLE OF epis_multi_prof_resp.update_time%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column UPDATE_INSTITUTION
    TYPE update_institution_cc IS TABLE OF epis_multi_prof_resp.update_institution%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_MAIN_RESPONSIBLE
    TYPE flg_main_responsible_cc IS TABLE OF epis_multi_prof_resp.flg_main_responsible%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column ID_SPECIALITY
    TYPE id_speciality_cc IS TABLE OF epis_multi_prof_resp.id_speciality%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column FLG_RESP_TYPE
    TYPE flg_resp_type_cc IS TABLE OF epis_multi_prof_resp.flg_resp_type%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column PRIORITY
    TYPE priority_cc IS TABLE OF epis_multi_prof_resp.priority%TYPE INDEX BY BINARY_INTEGER;
    -- Column Collection based on column DT_UPDATE
    TYPE dt_update_cc IS TABLE OF epis_multi_prof_resp.dt_update%TYPE INDEX BY BINARY_INTEGER;

    -- Insert one row, providing primary key if present (with rows_out)
    PROCEDURE ins
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    -- Insert one row, providing primary key if present (without rows_out)
    PROCEDURE ins
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN epis_multi_prof_resp%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a row based on a record
    -- Specify whether or not a primary key value should be generated
    PROCEDURE ins
    (
        rec_in          IN epis_multi_prof_resp%ROWTYPE,
        gen_pky_in      IN BOOLEAN DEFAULT FALSE,
        sequence_in     IN VARCHAR2 := NULL,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN epis_multi_prof_resp_tc,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert a collection of rows using FORALL; all primary key values
    -- must have already been generated, or are handled in triggers
    PROCEDURE ins
    (
        rows_in         IN epis_multi_prof_resp_tc,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Return next primary key value using the named sequence
    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_episode_in           IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in           IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in          IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in            IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in    IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in          IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in          IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in          IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in        IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in             IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in            IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, generating hidden primary key using a sequence
    PROCEDURE ins
    (
        id_episode_in           IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in           IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in          IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in            IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in    IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in          IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in          IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in          IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in        IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in             IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in            IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_episode_in               IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in               IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in          IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in              IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in                IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in        IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in              IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in     IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in            IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in            IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in                 IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in                IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        id_epis_multi_prof_resp_out IN OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Insert one row, returning primary key generated by sequence
    PROCEDURE ins
    (
        id_episode_in               IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in               IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in          IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in              IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in                IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in        IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in              IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in              IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in       IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in              IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in              IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in       IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in     IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in            IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in            IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in                 IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in                IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        id_epis_multi_prof_resp_out IN OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_episode_in           IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in           IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in          IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in            IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in    IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in          IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in          IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in          IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in        IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in             IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in            IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    ) RETURN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;

    -- Insert one row with function, return generated primary key
    FUNCTION ins
    (
        id_episode_in           IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in           IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in          IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in            IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in    IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in          IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in          IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in   IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in          IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in          IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in   IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in        IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        priority_in             IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in            IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        -- Pass false if you want errors to propagate out unhandled
        handle_error_in IN BOOLEAN := TRUE
    ) RETURN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        flg_profile_nin            IN BOOLEAN := TRUE,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        dt_create_nin              IN BOOLEAN := TRUE,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        id_epis_prof_resp_nin      IN BOOLEAN := TRUE,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        flg_main_responsible_nin   IN BOOLEAN := TRUE,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin          IN BOOLEAN := TRUE,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        flg_resp_type_nin          IN BOOLEAN := TRUE,
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        priority_nin               IN BOOLEAN := TRUE,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        dt_update_nin              IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    -- Update any/all columns by primary key. If you pass NULL, then
    -- the current column value is set to itself. If you need a more
    -- selected UPDATE then use one of the onecol procedures below.
    PROCEDURE upd
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        flg_profile_nin            IN BOOLEAN := TRUE,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        dt_create_nin              IN BOOLEAN := TRUE,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        id_epis_prof_resp_nin      IN BOOLEAN := TRUE,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_user_nin            IN BOOLEAN := TRUE,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_time_nin            IN BOOLEAN := TRUE,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        create_institution_nin     IN BOOLEAN := TRUE,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_user_nin            IN BOOLEAN := TRUE,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_time_nin            IN BOOLEAN := TRUE,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        update_institution_nin     IN BOOLEAN := TRUE,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        flg_main_responsible_nin   IN BOOLEAN := TRUE,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin          IN BOOLEAN := TRUE,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        flg_resp_type_nin          IN BOOLEAN := TRUE,
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        priority_nin               IN BOOLEAN := TRUE,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        dt_update_nin              IN BOOLEAN := TRUE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_episode_in            IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        flg_status_in            IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        id_professional_in       IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        id_professional_nin      IN BOOLEAN := TRUE,
        flg_profile_in           IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        flg_profile_nin          IN BOOLEAN := TRUE,
        dt_create_in             IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        dt_create_nin            IN BOOLEAN := TRUE,
        id_epis_prof_resp_in     IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        id_epis_prof_resp_nin    IN BOOLEAN := TRUE,
        create_user_in           IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_main_responsible_in  IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        flg_main_responsible_nin IN BOOLEAN := TRUE,
        id_speciality_in         IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin        IN BOOLEAN := TRUE,
        flg_resp_type_in         IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        flg_resp_type_nin        IN BOOLEAN := TRUE,
        priority_in              IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        priority_nin             IN BOOLEAN := TRUE,
        dt_update_in             IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        dt_update_nin            IN BOOLEAN := TRUE,
        where_in                 IN VARCHAR2,
        handle_error_in          IN BOOLEAN := TRUE,
        rows_out                 IN OUT table_varchar
    );

    --Update any/all columns by dynamic WHERE
    -- If you pass NULL, then the current column value is set to itself
    PROCEDURE upd
    (
        id_episode_in            IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        id_episode_nin           IN BOOLEAN := TRUE,
        flg_status_in            IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        flg_status_nin           IN BOOLEAN := TRUE,
        id_professional_in       IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        id_professional_nin      IN BOOLEAN := TRUE,
        flg_profile_in           IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        flg_profile_nin          IN BOOLEAN := TRUE,
        dt_create_in             IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        dt_create_nin            IN BOOLEAN := TRUE,
        id_epis_prof_resp_in     IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        id_epis_prof_resp_nin    IN BOOLEAN := TRUE,
        create_user_in           IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_user_nin          IN BOOLEAN := TRUE,
        create_time_in           IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_time_nin          IN BOOLEAN := TRUE,
        create_institution_in    IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        create_institution_nin   IN BOOLEAN := TRUE,
        update_user_in           IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_user_nin          IN BOOLEAN := TRUE,
        update_time_in           IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_time_nin          IN BOOLEAN := TRUE,
        update_institution_in    IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        update_institution_nin   IN BOOLEAN := TRUE,
        flg_main_responsible_in  IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        flg_main_responsible_nin IN BOOLEAN := TRUE,
        id_speciality_in         IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin        IN BOOLEAN := TRUE,
        flg_resp_type_in         IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        flg_resp_type_nin        IN BOOLEAN := TRUE,
        priority_in              IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        priority_nin             IN BOOLEAN := TRUE,
        dt_update_in             IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        dt_update_nin            IN BOOLEAN := TRUE,
        where_in                 IN VARCHAR2,
        handle_error_in          IN BOOLEAN := TRUE
    );

    --Update/insert with columns (with rows_out)
    PROCEDURE upd_ins
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   IN OUT table_varchar
    );

    --Update/insert with columns (without rows_out)
    PROCEDURE upd_ins
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        id_episode_in              IN epis_multi_prof_resp.id_episode%TYPE DEFAULT NULL,
        flg_status_in              IN epis_multi_prof_resp.flg_status%TYPE DEFAULT NULL,
        id_professional_in         IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        flg_profile_in             IN epis_multi_prof_resp.flg_profile%TYPE DEFAULT NULL,
        dt_create_in               IN epis_multi_prof_resp.dt_create%TYPE DEFAULT NULL,
        id_epis_prof_resp_in       IN epis_multi_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        create_user_in             IN epis_multi_prof_resp.create_user%TYPE DEFAULT NULL,
        create_time_in             IN epis_multi_prof_resp.create_time%TYPE DEFAULT NULL,
        create_institution_in      IN epis_multi_prof_resp.create_institution%TYPE DEFAULT NULL,
        update_user_in             IN epis_multi_prof_resp.update_user%TYPE DEFAULT NULL,
        update_time_in             IN epis_multi_prof_resp.update_time%TYPE DEFAULT NULL,
        update_institution_in      IN epis_multi_prof_resp.update_institution%TYPE DEFAULT NULL,
        flg_main_responsible_in    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT NULL,
        id_speciality_in           IN epis_multi_prof_resp.id_speciality%TYPE DEFAULT NULL,
        flg_resp_type_in           IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        priority_in                IN epis_multi_prof_resp.priority%TYPE DEFAULT NULL,
        dt_update_in               IN epis_multi_prof_resp.dt_update%TYPE DEFAULT NULL,
        handle_error_in            IN BOOLEAN := TRUE
    );

    --Update record (with rows_out)
    PROCEDURE upd
    (
        rec_in          IN epis_multi_prof_resp%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        IN OUT table_varchar
    );

    --Update record (without rows_out)
    PROCEDURE upd
    (
        rec_in          IN epis_multi_prof_resp%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    --Update collection (with rows_out)
    PROCEDURE upd
    (
        col_in            IN epis_multi_prof_resp_tc,
        ignore_if_null_in IN BOOLEAN := TRUE,
        handle_error_in   IN BOOLEAN := TRUE,
        rows_out          IN OUT table_varchar
    );

    --Update collection (without rows_out)
    PROCEDURE upd
    (
        col_in            IN epis_multi_prof_resp_tc,
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
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        handle_error_in            IN BOOLEAN := TRUE,
        rows_out                   OUT table_varchar
    );

    -- Delete one row by primary key
    PROCEDURE del
    (
        id_epis_multi_prof_resp_in IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        handle_error_in            IN BOOLEAN := TRUE
    );

    -- Delete for unique value of EMPR_EPR_UK
    PROCEDURE del_empr_epr_uk
    (
        id_epis_prof_resp_in IN epis_multi_prof_resp.id_epis_prof_resp%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete for unique value of EMPR_EPR_UK
    PROCEDURE del_empr_epr_uk
    (
        id_epis_prof_resp_in IN epis_multi_prof_resp.id_epis_prof_resp%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
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

    -- Delete all rows for this EMPR_EPIS_FK foreign key value
    PROCEDURE del_empr_epis_fk
    (
        id_episode_in   IN epis_multi_prof_resp.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE,
        rows_out        OUT table_varchar
    );

    -- Delete all rows for this EMPR_EPR_FK foreign key value
    PROCEDURE del_empr_epr_fk
    (
        id_epis_prof_resp_in IN epis_multi_prof_resp.id_epis_prof_resp%TYPE,
        handle_error_in      IN BOOLEAN := TRUE,
        rows_out             OUT table_varchar
    );

    -- Delete all rows for this EMPR_PROF_FK foreign key value
    PROCEDURE del_empr_prof_fk
    (
        id_professional_in IN epis_multi_prof_resp.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE,
        rows_out           OUT table_varchar
    );

    -- Delete all rows for this EMPR_SPY_FK foreign key value
    PROCEDURE del_empr_spy_fk
    (
        id_speciality_in IN epis_multi_prof_resp.id_speciality%TYPE,
        handle_error_in  IN BOOLEAN := TRUE,
        rows_out         OUT table_varchar
    );

    -- Delete all rows for this EMPR_EPIS_FK foreign key value
    PROCEDURE del_empr_epis_fk
    (
        id_episode_in   IN epis_multi_prof_resp.id_episode%TYPE,
        handle_error_in IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EMPR_EPR_FK foreign key value
    PROCEDURE del_empr_epr_fk
    (
        id_epis_prof_resp_in IN epis_multi_prof_resp.id_epis_prof_resp%TYPE,
        handle_error_in      IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EMPR_PROF_FK foreign key value
    PROCEDURE del_empr_prof_fk
    (
        id_professional_in IN epis_multi_prof_resp.id_professional%TYPE,
        handle_error_in    IN BOOLEAN := TRUE
    );

    -- Delete all rows for this EMPR_SPY_FK foreign key value
    PROCEDURE del_empr_spy_fk
    (
        id_speciality_in IN epis_multi_prof_resp.id_speciality%TYPE,
        handle_error_in  IN BOOLEAN := TRUE
    );

    -- Initialize a record with default values for columns in the table (prc)
    PROCEDURE initrec(epis_multi_prof_resp_inout IN OUT epis_multi_prof_resp%ROWTYPE);

    -- Initialize a record with default values for columns in the table (fnc)
    FUNCTION initrec RETURN epis_multi_prof_resp%ROWTYPE;

    -- Get data rowid
    FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_multi_prof_resp_tc;

    -- Get data rowid pragma autonomous transaccion
    FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_multi_prof_resp_tc;

END ts_epis_multi_prof_resp;
/
