/*-- Last Change Revision: $Rev: 2029390 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_STD_PRESC_DIR_INTERVAL
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: July 29, 2010 16:52:43
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "STD_PRESC_DIR_INTERVAL"
     TYPE STD_PRESC_DIR_INTERVAL_tc IS TABLE OF STD_PRESC_DIR_INTERVAL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE std_presc_dir_interval_ntt IS TABLE OF STD_PRESC_DIR_INTERVAL%ROWTYPE;
     TYPE std_presc_dir_interval_vat IS VARRAY(100) OF STD_PRESC_DIR_INTERVAL%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF STD_PRESC_DIR_INTERVAL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF STD_PRESC_DIR_INTERVAL%ROWTYPE;
     TYPE vat IS VARRAY(100) OF STD_PRESC_DIR_INTERVAL%ROWTYPE;

   -- Column Collection based on column "ID_PRESC_DIR_INTERVAL"
   TYPE ID_PRESC_DIR_INTERVAL_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PRESC_DIRECTIONS"
   TYPE ID_PRESC_DIRECTIONS_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "RANK"
   TYPE RANK_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.RANK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DURATION"
   TYPE DURATION_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.DURATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_UNIT_DURATION"
   TYPE ID_UNIT_DURATION_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_BEGIN"
   TYPE DT_BEGIN_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_END"
   TYPE DT_END_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.DT_END%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      ,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      ,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN STD_PRESC_DIR_INTERVAL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN STD_PRESC_DIR_INTERVAL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN STD_PRESC_DIR_INTERVAL_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN STD_PRESC_DIR_INTERVAL_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_presc_dir_interval_out IN OUT STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_presc_dir_interval_out IN OUT STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      ;

   FUNCTION ins (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      ID_PRESC_DIRECTIONS_nin IN BOOLEAN := TRUE,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      DURATION_nin IN BOOLEAN := TRUE,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      ID_UNIT_DURATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      ID_PRESC_DIRECTIONS_nin IN BOOLEAN := TRUE,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      DURATION_nin IN BOOLEAN := TRUE,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      ID_UNIT_DURATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      ID_PRESC_DIRECTIONS_nin IN BOOLEAN := TRUE,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      DURATION_nin IN BOOLEAN := TRUE,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      ID_UNIT_DURATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      ID_PRESC_DIRECTIONS_nin IN BOOLEAN := TRUE,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      DURATION_nin IN BOOLEAN := TRUE,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      ID_UNIT_DURATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE,
      id_presc_directions_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIRECTIONS%TYPE DEFAULT NULL,
      rank_in IN STD_PRESC_DIR_INTERVAL.RANK%TYPE DEFAULT NULL,
      duration_in IN STD_PRESC_DIR_INTERVAL.DURATION%TYPE DEFAULT NULL,
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE DEFAULT NULL,
      dt_begin_in IN STD_PRESC_DIR_INTERVAL.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN STD_PRESC_DIR_INTERVAL.DT_END%TYPE DEFAULT NULL,
      create_user_in IN STD_PRESC_DIR_INTERVAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN STD_PRESC_DIR_INTERVAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN STD_PRESC_DIR_INTERVAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN STD_PRESC_DIR_INTERVAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN STD_PRESC_DIR_INTERVAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN STD_PRESC_DIR_INTERVAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN STD_PRESC_DIR_INTERVAL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN STD_PRESC_DIR_INTERVAL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN STD_PRESC_DIR_INTERVAL_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN STD_PRESC_DIR_INTERVAL_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
      );





   -- Use Native Dynamic SQL increment a single NUMBER column
   -- for all rows specified by the dynamic WHERE clause
   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
   );









    -- Delete one row by primary key
   PROCEDURE del (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PRESC_DIR_INTERVAL
   PROCEDURE del_ID_PRESC_DIR_INTERVAL (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PRESC_DIR_INTERVAL
   PROCEDURE del_ID_PRESC_DIR_INTERVAL (
      id_presc_dir_interval_in IN STD_PRESC_DIR_INTERVAL.ID_PRESC_DIR_INTERVAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this SPD_UM_FK foreign key value
   PROCEDURE del_SPD_UM_FK (
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this SPD_UM_FK foreign key value
   PROCEDURE del_SPD_UM_FK (
      id_unit_duration_in IN STD_PRESC_DIR_INTERVAL.ID_UNIT_DURATION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows specified by dynamic WHERE clause
   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows specified by dynamic WHERE clause
   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified VARCHAR2 column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      );


      -- Delete all rows where the specified VARCHAR2 column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified DATE column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified DATE column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


      -- Delete all rows where the specified TIMESTAMP column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified TIMESTAMP column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

    -- Delete all rows where the specified NUMBER column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows where the specified NUMBER column has
   -- a value that matches the specfified value.
   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Initialize a record with default values for columns in the table.
   PROCEDURE initrec (
      std_presc_dir_interval_inout IN OUT STD_PRESC_DIR_INTERVAL%ROWTYPE
   );

   FUNCTION initrec RETURN STD_PRESC_DIR_INTERVAL%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN STD_PRESC_DIR_INTERVAL_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN STD_PRESC_DIR_INTERVAL_tc;

END TS_STD_PRESC_DIR_INTERVAL;
/
