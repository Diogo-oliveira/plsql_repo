/*-- Last Change Revision: $Rev: 1668928 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-12-05 11:18:55 +0000 (sex, 05 dez 2014) $*/
CREATE OR REPLACE PACKAGE TS_NURSE_TEA_REQ_DIAG_HIST
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: December 4, 2014 15:55:45
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NURSE_TEA_REQ_DIAG_HIST"
     TYPE NURSE_TEA_REQ_DIAG_HIST_tc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nurse_tea_req_diag_hist_ntt IS TABLE OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE;
     TYPE nurse_tea_req_diag_hist_vat IS VARRAY(100) OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NURSE_TEA_REQ_DIAG_HIST%ROWTYPE;

   -- Column Collection based on column "ID_NURSE_TEA_REQ_DIAG_HIST"
   TYPE ID_NURSE_TEA_REQ_DIAG_HIST_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NURSE_TEA_REQ_DIAG"
   TYPE ID_NURSE_TEA_REQ_DIAG_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NURSE_TEA_REQ"
   TYPE ID_NURSE_TEA_REQ_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DIAGNOSIS"
   TYPE ID_DIAGNOSIS_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_COMPOSITION"
   TYPE ID_COMPOSITION_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_NURSE_TEA_REQ_DIAG_TSTZ"
   TYPE DT_NURSE_TEA_REQ_DIAG_TSTZ_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NURSE_TEA_REQ_HIST"
   TYPE ID_NURSE_TEA_REQ_HIST_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NAN_DIAGNOSIS"
   TYPE ID_NAN_DIAGNOSIS_cc IS TABLE OF NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      ,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      ,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NURSE_TEA_REQ_DIAG_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NURSE_TEA_REQ_DIAG_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NURSE_TEA_REQ_DIAG_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NURSE_TEA_REQ_DIAG_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nurse_tea_req_diag_hist_out IN OUT NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      id_nurse_tea_req_diag_hist_out IN OUT NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      ;

   FUNCTION ins (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_DIAG_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_nin IN BOOLEAN := TRUE,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      DT_NURSE_TEA_REQ_DIAG_TSTZ_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_HIST_nin IN BOOLEAN := TRUE,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_NAN_DIAGNOSIS_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_DIAG_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_nin IN BOOLEAN := TRUE,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      DT_NURSE_TEA_REQ_DIAG_TSTZ_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_HIST_nin IN BOOLEAN := TRUE,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_NAN_DIAGNOSIS_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_DIAG_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_nin IN BOOLEAN := TRUE,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      DT_NURSE_TEA_REQ_DIAG_TSTZ_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_HIST_nin IN BOOLEAN := TRUE,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_NAN_DIAGNOSIS_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_DIAG_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_nin IN BOOLEAN := TRUE,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_DIAGNOSIS_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      DT_NURSE_TEA_REQ_DIAG_TSTZ_nin IN BOOLEAN := TRUE,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      ID_NURSE_TEA_REQ_HIST_nin IN BOOLEAN := TRUE,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
      ID_NAN_DIAGNOSIS_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE,
      id_nurse_tea_req_diag_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG%TYPE DEFAULT NULL,
      id_nurse_tea_req_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ%TYPE DEFAULT NULL,
      id_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_DIAGNOSIS%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_REQ_DIAG_HIST.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_REQ_DIAG_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_REQ_DIAG_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      dt_nurse_tea_req_diag_tstz_in IN NURSE_TEA_REQ_DIAG_HIST.DT_NURSE_TEA_REQ_DIAG_TSTZ%TYPE DEFAULT NULL,
      id_nurse_tea_req_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_HIST%TYPE DEFAULT NULL,
      id_nan_diagnosis_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NAN_DIAGNOSIS%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NURSE_TEA_REQ_DIAG_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NURSE_TEA_REQ_DIAG_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NURSE_TEA_REQ_DIAG_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NURSE_TEA_REQ_DIAG_HIST_tc,
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
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NURSE_TEA_REQ_DIAG_HIST
   PROCEDURE del_ID_NURSE_TEA_REQ_DIAG_HIST (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NURSE_TEA_REQ_DIAG_HIST
   PROCEDURE del_ID_NURSE_TEA_REQ_DIAG_HIST (
      id_nurse_tea_req_diag_hist_in IN NURSE_TEA_REQ_DIAG_HIST.ID_NURSE_TEA_REQ_DIAG_HIST%TYPE
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
      nurse_tea_req_diag_hist_inout IN OUT NURSE_TEA_REQ_DIAG_HIST%ROWTYPE
   );

   FUNCTION initrec RETURN NURSE_TEA_REQ_DIAG_HIST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_REQ_DIAG_HIST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_REQ_DIAG_HIST_tc;

END TS_NURSE_TEA_REQ_DIAG_HIST;
/
