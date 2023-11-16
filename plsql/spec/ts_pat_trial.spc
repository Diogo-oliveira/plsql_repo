/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE TS_PAT_TRIAL
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 1, 2011 15:6:54
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PAT_TRIAL"
     TYPE PAT_TRIAL_tc IS TABLE OF PAT_TRIAL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE pat_trial_ntt IS TABLE OF PAT_TRIAL%ROWTYPE;
     TYPE pat_trial_vat IS VARRAY(100) OF PAT_TRIAL%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PAT_TRIAL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PAT_TRIAL%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PAT_TRIAL%ROWTYPE;

   -- Column Collection based on column "ID_PAT_TRIAL"
   TYPE ID_PAT_TRIAL_cc IS TABLE OF PAT_TRIAL.ID_PAT_TRIAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PATIENT"
   TYPE ID_PATIENT_cc IS TABLE OF PAT_TRIAL.ID_PATIENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_TRIAL"
   TYPE ID_TRIAL_cc IS TABLE OF PAT_TRIAL.ID_TRIAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_RECORD"
   TYPE DT_RECORD_cc IS TABLE OF PAT_TRIAL.DT_RECORD%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_RECORD"
   TYPE ID_PROF_RECORD_cc IS TABLE OF PAT_TRIAL.ID_PROF_RECORD%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_TRIAL_BEGIN"
   TYPE DT_TRIAL_BEGIN_cc IS TABLE OF PAT_TRIAL.DT_TRIAL_BEGIN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF PAT_TRIAL.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_START"
   TYPE DT_START_cc IS TABLE OF PAT_TRIAL.DT_START%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_END"
   TYPE DT_END_cc IS TABLE OF PAT_TRIAL.DT_END%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF PAT_TRIAL.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_INFO_DET"
   TYPE ID_CANCEL_INFO_DET_cc IS TABLE OF PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PAT_TRIAL.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PAT_TRIAL.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PAT_TRIAL.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PAT_TRIAL.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PAT_TRIAL.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PAT_TRIAL.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF PAT_TRIAL.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
      ,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
      ,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PAT_TRIAL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PAT_TRIAL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PAT_TRIAL_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PAT_TRIAL_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PAT_TRIAL.ID_PAT_TRIAL%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      id_pat_trial_out IN OUT PAT_TRIAL.ID_PAT_TRIAL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      id_pat_trial_out IN OUT PAT_TRIAL.ID_PAT_TRIAL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PAT_TRIAL.ID_PAT_TRIAL%TYPE
      ;

   FUNCTION ins (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PAT_TRIAL.ID_PAT_TRIAL%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      ID_TRIAL_nin IN BOOLEAN := TRUE,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      DT_RECORD_nin IN BOOLEAN := TRUE,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      ID_PROF_RECORD_nin IN BOOLEAN := TRUE,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      DT_TRIAL_BEGIN_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      DT_START_nin IN BOOLEAN := TRUE,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      ID_TRIAL_nin IN BOOLEAN := TRUE,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      DT_RECORD_nin IN BOOLEAN := TRUE,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      ID_PROF_RECORD_nin IN BOOLEAN := TRUE,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      DT_TRIAL_BEGIN_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      DT_START_nin IN BOOLEAN := TRUE,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      ID_TRIAL_nin IN BOOLEAN := TRUE,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      DT_RECORD_nin IN BOOLEAN := TRUE,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      ID_PROF_RECORD_nin IN BOOLEAN := TRUE,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      DT_TRIAL_BEGIN_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      DT_START_nin IN BOOLEAN := TRUE,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      ID_TRIAL_nin IN BOOLEAN := TRUE,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      DT_RECORD_nin IN BOOLEAN := TRUE,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      ID_PROF_RECORD_nin IN BOOLEAN := TRUE,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      DT_TRIAL_BEGIN_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      DT_START_nin IN BOOLEAN := TRUE,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE,
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE DEFAULT NULL,
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE DEFAULT NULL,
      dt_record_in IN PAT_TRIAL.DT_RECORD%TYPE DEFAULT NULL,
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE DEFAULT NULL,
      dt_trial_begin_in IN PAT_TRIAL.DT_TRIAL_BEGIN%TYPE DEFAULT NULL,
      flg_status_in IN PAT_TRIAL.FLG_STATUS%TYPE DEFAULT NULL,
      dt_start_in IN PAT_TRIAL.DT_START%TYPE DEFAULT NULL,
      dt_end_in IN PAT_TRIAL.DT_END%TYPE DEFAULT NULL,
      id_institution_in IN PAT_TRIAL.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PAT_TRIAL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PAT_TRIAL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PAT_TRIAL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PAT_TRIAL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PAT_TRIAL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PAT_TRIAL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PAT_TRIAL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PAT_TRIAL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PAT_TRIAL_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PAT_TRIAL_tc,
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
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PAT_TRIAL
   PROCEDURE del_ID_PAT_TRIAL (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PAT_TRIAL
   PROCEDURE del_ID_PAT_TRIAL (
      id_pat_trial_in IN PAT_TRIAL.ID_PAT_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this PT_CID_FK foreign key value
   PROCEDURE del_PT_CID_FK (
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PT_CID_FK foreign key value
   PROCEDURE del_PT_CID_FK (
      id_cancel_info_det_in IN PAT_TRIAL.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PT_EPIS_FK foreign key value
   PROCEDURE del_PT_EPIS_FK (
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PT_EPIS_FK foreign key value
   PROCEDURE del_PT_EPIS_FK (
      id_episode_in IN PAT_TRIAL.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PT_P_FK foreign key value
   PROCEDURE del_PT_P_FK (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PT_P_FK foreign key value
   PROCEDURE del_PT_P_FK (
      id_patient_in IN PAT_TRIAL.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PT_PROF_FK foreign key value
   PROCEDURE del_PT_PROF_FK (
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PT_PROF_FK foreign key value
   PROCEDURE del_PT_PROF_FK (
      id_prof_record_in IN PAT_TRIAL.ID_PROF_RECORD%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PT_T_FK foreign key value
   PROCEDURE del_PT_T_FK (
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PT_T_FK foreign key value
   PROCEDURE del_PT_T_FK (
      id_trial_in IN PAT_TRIAL.ID_TRIAL%TYPE
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
      pat_trial_inout IN OUT PAT_TRIAL%ROWTYPE
   );

   FUNCTION initrec RETURN PAT_TRIAL%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PAT_TRIAL_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PAT_TRIAL_tc;

END TS_PAT_TRIAL;
/