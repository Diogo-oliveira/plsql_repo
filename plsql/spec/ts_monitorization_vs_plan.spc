/*-- Last Change Revision: $Rev: 2029248 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_MONITORIZATION_VS_PLAN
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Abril 18, 2011 12:26:39
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "MONITORIZATION_VS_PLAN"
     TYPE MONITORIZATION_VS_PLAN_tc IS TABLE OF MONITORIZATION_VS_PLAN%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE monitorization_vs_plan_ntt IS TABLE OF MONITORIZATION_VS_PLAN%ROWTYPE;
     TYPE monitorization_vs_plan_vat IS VARRAY(100) OF MONITORIZATION_VS_PLAN%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF MONITORIZATION_VS_PLAN%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF MONITORIZATION_VS_PLAN%ROWTYPE;
     TYPE vat IS VARRAY(100) OF MONITORIZATION_VS_PLAN%ROWTYPE;

   -- Column Collection based on column "ID_MONITORIZATION_VS_PLAN"
   TYPE ID_MONITORIZATION_VS_PLAN_cc IS TABLE OF MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_MONITORIZATION_VS"
   TYPE ID_MONITORIZATION_VS_cc IS TABLE OF MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_PLAN_TSTZ"
   TYPE DT_PLAN_TSTZ_cc IS TABLE OF MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_PERFORMED"
   TYPE ID_PROF_PERFORMED_cc IS TABLE OF MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "START_TIME"
   TYPE START_TIME_cc IS TABLE OF MONITORIZATION_VS_PLAN.START_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "END_TIME"
   TYPE END_TIME_cc IS TABLE OF MONITORIZATION_VS_PLAN.END_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF MONITORIZATION_VS_PLAN.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS_PREV"
   TYPE FLG_STATUS_PREV_cc IS TABLE OF MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      ,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      ,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN MONITORIZATION_VS_PLAN%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN MONITORIZATION_VS_PLAN%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN MONITORIZATION_VS_PLAN_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN MONITORIZATION_VS_PLAN_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      id_monitorization_vs_plan_out IN OUT MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      id_monitorization_vs_plan_out IN OUT MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      ;

   FUNCTION ins (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      ID_MONITORIZATION_VS_nin IN BOOLEAN := TRUE,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      DT_PLAN_TSTZ_nin IN BOOLEAN := TRUE,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      ID_PROF_PERFORMED_nin IN BOOLEAN := TRUE,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      START_TIME_nin IN BOOLEAN := TRUE,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      END_TIME_nin IN BOOLEAN := TRUE,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      FLG_STATUS_PREV_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      ID_MONITORIZATION_VS_nin IN BOOLEAN := TRUE,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      DT_PLAN_TSTZ_nin IN BOOLEAN := TRUE,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      ID_PROF_PERFORMED_nin IN BOOLEAN := TRUE,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      START_TIME_nin IN BOOLEAN := TRUE,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      END_TIME_nin IN BOOLEAN := TRUE,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      FLG_STATUS_PREV_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      ID_MONITORIZATION_VS_nin IN BOOLEAN := TRUE,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      DT_PLAN_TSTZ_nin IN BOOLEAN := TRUE,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      ID_PROF_PERFORMED_nin IN BOOLEAN := TRUE,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      START_TIME_nin IN BOOLEAN := TRUE,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      END_TIME_nin IN BOOLEAN := TRUE,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      FLG_STATUS_PREV_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      ID_MONITORIZATION_VS_nin IN BOOLEAN := TRUE,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      DT_PLAN_TSTZ_nin IN BOOLEAN := TRUE,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      ID_PROF_PERFORMED_nin IN BOOLEAN := TRUE,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      START_TIME_nin IN BOOLEAN := TRUE,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      END_TIME_nin IN BOOLEAN := TRUE,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
      FLG_STATUS_PREV_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE,
      flg_status_in IN MONITORIZATION_VS_PLAN.FLG_STATUS%TYPE DEFAULT NULL,
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE DEFAULT NULL,
      dt_plan_tstz_in IN MONITORIZATION_VS_PLAN.DT_PLAN_TSTZ%TYPE DEFAULT NULL,
      id_prof_performed_in IN MONITORIZATION_VS_PLAN.ID_PROF_PERFORMED%TYPE DEFAULT NULL,
      start_time_in IN MONITORIZATION_VS_PLAN.START_TIME%TYPE DEFAULT NULL,
      end_time_in IN MONITORIZATION_VS_PLAN.END_TIME%TYPE DEFAULT NULL,
      create_user_in IN MONITORIZATION_VS_PLAN.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN MONITORIZATION_VS_PLAN.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN MONITORIZATION_VS_PLAN.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN MONITORIZATION_VS_PLAN.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN MONITORIZATION_VS_PLAN.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN MONITORIZATION_VS_PLAN.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      flg_status_prev_in IN MONITORIZATION_VS_PLAN.FLG_STATUS_PREV%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN MONITORIZATION_VS_PLAN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN MONITORIZATION_VS_PLAN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN MONITORIZATION_VS_PLAN_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN MONITORIZATION_VS_PLAN_tc,
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
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_MONITORIZATION_VS_PLAN
   PROCEDURE del_ID_MONITORIZATION_VS_PLAN (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_MONITORIZATION_VS_PLAN
   PROCEDURE del_ID_MONITORIZATION_VS_PLAN (
      id_monitorization_vs_plan_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this MVSP_MVS_FK foreign key value
   PROCEDURE del_MVSP_MVS_FK (
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this MVSP_MVS_FK foreign key value
   PROCEDURE del_MVSP_MVS_FK (
      id_monitorization_vs_in IN MONITORIZATION_VS_PLAN.ID_MONITORIZATION_VS%TYPE
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
      monitorization_vs_plan_inout IN OUT MONITORIZATION_VS_PLAN%ROWTYPE
   );

   FUNCTION initrec RETURN MONITORIZATION_VS_PLAN%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN MONITORIZATION_VS_PLAN_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN MONITORIZATION_VS_PLAN_tc;

END TS_MONITORIZATION_VS_PLAN;
/
