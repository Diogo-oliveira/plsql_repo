/*-- Last Change Revision: $Rev: 2029270 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_P1_MATCH
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: October 16, 2008 18:55:53
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "P1_MATCH"
     TYPE P1_MATCH_tc IS TABLE OF P1_MATCH%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE p1_match_ntt IS TABLE OF P1_MATCH%ROWTYPE;
     TYPE p1_match_vat IS VARRAY(100) OF P1_MATCH%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF P1_MATCH%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF P1_MATCH%ROWTYPE;
     TYPE vat IS VARRAY(100) OF P1_MATCH%ROWTYPE;

   -- Column Collection based on column "ID_MATCH"
   TYPE ID_MATCH_cc IS TABLE OF P1_MATCH.ID_MATCH%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PATIENT"
   TYPE ID_PATIENT_cc IS TABLE OF P1_MATCH.ID_PATIENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CLIN_RECORD"
   TYPE ID_CLIN_RECORD_cc IS TABLE OF P1_MATCH.ID_CLIN_RECORD%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF P1_MATCH.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "SEQUENTIAL_NUMBER_NUMBER"
   TYPE SEQUENTIAL_NUMBER_NUMBER_cc IS TABLE OF P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF P1_MATCH.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CREATE"
   TYPE ID_PROF_CREATE_cc IS TABLE OF P1_MATCH.ID_PROF_CREATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CANCEL"
   TYPE ID_PROF_CANCEL_cc IS TABLE OF P1_MATCH.ID_PROF_CANCEL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_MATCH_PREV"
   TYPE ID_MATCH_PREV_cc IS TABLE OF P1_MATCH.ID_MATCH_PREV%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATE_TSTZ"
   TYPE DT_CREATE_TSTZ_cc IS TABLE OF P1_MATCH.DT_CREATE_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CANCEL_TSTZ"
   TYPE DT_CANCEL_TSTZ_cc IS TABLE OF P1_MATCH.DT_CANCEL_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "SEQUENTIAL_NUMBER"
   TYPE SEQUENTIAL_NUMBER_cc IS TABLE OF P1_MATCH.SEQUENTIAL_NUMBER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF P1_MATCH.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
      ,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
      ,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN P1_MATCH%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN P1_MATCH%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN P1_MATCH_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN P1_MATCH_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN P1_MATCH.ID_MATCH%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      id_match_out IN OUT P1_MATCH.ID_MATCH%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      id_match_out IN OUT P1_MATCH.ID_MATCH%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         P1_MATCH.ID_MATCH%TYPE
      ;

   FUNCTION ins (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT 'A'
,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT current_timestamp
,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         P1_MATCH.ID_MATCH%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      ID_CLIN_RECORD_nin IN BOOLEAN := TRUE,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_NUMBER_nin IN BOOLEAN := TRUE,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      ID_MATCH_PREV_nin IN BOOLEAN := TRUE,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      DT_CREATE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      DT_CANCEL_TSTZ_nin IN BOOLEAN := TRUE,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_nin IN BOOLEAN := TRUE,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      ID_CLIN_RECORD_nin IN BOOLEAN := TRUE,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_NUMBER_nin IN BOOLEAN := TRUE,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      ID_MATCH_PREV_nin IN BOOLEAN := TRUE,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      DT_CREATE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      DT_CANCEL_TSTZ_nin IN BOOLEAN := TRUE,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_nin IN BOOLEAN := TRUE,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      ID_CLIN_RECORD_nin IN BOOLEAN := TRUE,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_NUMBER_nin IN BOOLEAN := TRUE,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      ID_MATCH_PREV_nin IN BOOLEAN := TRUE,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      DT_CREATE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      DT_CANCEL_TSTZ_nin IN BOOLEAN := TRUE,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_nin IN BOOLEAN := TRUE,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      ID_CLIN_RECORD_nin IN BOOLEAN := TRUE,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_NUMBER_nin IN BOOLEAN := TRUE,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      ID_MATCH_PREV_nin IN BOOLEAN := TRUE,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      DT_CREATE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      DT_CANCEL_TSTZ_nin IN BOOLEAN := TRUE,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      SEQUENTIAL_NUMBER_nin IN BOOLEAN := TRUE,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE,
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE DEFAULT NULL,
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE DEFAULT NULL,
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE DEFAULT NULL,
      sequential_number_number_in IN P1_MATCH.SEQUENTIAL_NUMBER_NUMBER%TYPE DEFAULT NULL,
      flg_status_in IN P1_MATCH.FLG_STATUS%TYPE DEFAULT NULL,
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE DEFAULT NULL,
      dt_create_tstz_in IN P1_MATCH.DT_CREATE_TSTZ%TYPE DEFAULT NULL,
      dt_cancel_tstz_in IN P1_MATCH.DT_CANCEL_TSTZ%TYPE DEFAULT NULL,
      sequential_number_in IN P1_MATCH.SEQUENTIAL_NUMBER%TYPE DEFAULT NULL,
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN P1_MATCH%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN P1_MATCH%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN P1_MATCH_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN P1_MATCH_tc,
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
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_MATCH
   PROCEDURE del_ID_MATCH (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_MATCH
   PROCEDURE del_ID_MATCH (
      id_match_in IN P1_MATCH.ID_MATCH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this PMATCH_CLR_FK foreign key value
   PROCEDURE del_PMATCH_CLR_FK (
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_CLR_FK foreign key value
   PROCEDURE del_PMATCH_CLR_FK (
      id_clin_record_in IN P1_MATCH.ID_CLIN_RECORD%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_EPIS_FK foreign key value
   PROCEDURE del_PMATCH_EPIS_FK (
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_EPIS_FK foreign key value
   PROCEDURE del_PMATCH_EPIS_FK (
      id_episode_in IN P1_MATCH.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_INST_FK foreign key value
   PROCEDURE del_PMATCH_INST_FK (
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_INST_FK foreign key value
   PROCEDURE del_PMATCH_INST_FK (
      id_institution_in IN P1_MATCH.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_PAT_FK foreign key value
   PROCEDURE del_PMATCH_PAT_FK (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_PAT_FK foreign key value
   PROCEDURE del_PMATCH_PAT_FK (
      id_patient_in IN P1_MATCH.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_PMATCH_FK foreign key value
   PROCEDURE del_PMATCH_PMATCH_FK (
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_PMATCH_FK foreign key value
   PROCEDURE del_PMATCH_PMATCH_FK (
      id_match_prev_in IN P1_MATCH.ID_MATCH_PREV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_PROF_CNC_FK foreign key value
   PROCEDURE del_PMATCH_PROF_CNC_FK (
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_PROF_CNC_FK foreign key value
   PROCEDURE del_PMATCH_PROF_CNC_FK (
      id_prof_cancel_in IN P1_MATCH.ID_PROF_CANCEL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMATCH_PROF_CRT_FK foreign key value
   PROCEDURE del_PMATCH_PROF_CRT_FK (
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMATCH_PROF_CRT_FK foreign key value
   PROCEDURE del_PMATCH_PROF_CRT_FK (
      id_prof_create_in IN P1_MATCH.ID_PROF_CREATE%TYPE
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
      p1_match_inout IN OUT P1_MATCH%ROWTYPE
   );

   FUNCTION initrec RETURN P1_MATCH%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN P1_MATCH_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN P1_MATCH_tc;

END TS_P1_MATCH;
/
