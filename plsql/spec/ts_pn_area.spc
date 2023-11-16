/*-- Last Change Revision: $Rev: 1738197 $*/
/*-- Last Change by: $Author: vanessa.barsottelli $*/
/*-- Date of last change: $Date: 2016-05-19 12:02:03 +0100 (qui, 19 mai 2016) $*/
CREATE OR REPLACE PACKAGE TS_PN_AREA
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: May 6, 2016 12:11:3
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PN_AREA"
     TYPE PN_AREA_tc IS TABLE OF PN_AREA%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE pn_area_ntt IS TABLE OF PN_AREA%ROWTYPE;
     TYPE pn_area_vat IS VARRAY(100) OF PN_AREA%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PN_AREA%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PN_AREA%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PN_AREA%ROWTYPE;

   -- Column Collection based on column "ID_PN_AREA"
   TYPE ID_PN_AREA_cc IS TABLE OF PN_AREA.ID_PN_AREA%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "INTERNAL_NAME"
   TYPE INTERNAL_NAME_cc IS TABLE OF PN_AREA.INTERNAL_NAME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CODE_PN_AREA"
   TYPE CODE_PN_AREA_cc IS TABLE OF PN_AREA.CODE_PN_AREA%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "SCREEN_NAME"
   TYPE SCREEN_NAME_cc IS TABLE OF PN_AREA.SCREEN_NAME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PN_AREA.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PN_AREA.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PN_AREA.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PN_AREA.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PN_AREA.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PN_AREA.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CANCEL_REASON_NOTE"
   TYPE CANCEL_REASON_NOTE_cc IS TABLE OF PN_AREA.CANCEL_REASON_NOTE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CANCEL_REASON_ADDENDUM"
   TYPE CANCEL_REASON_ADDENDUM_cc IS TABLE OF PN_AREA.CANCEL_REASON_ADDENDUM%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "STEXT_ADDENDUM_CREATE"
   TYPE STEXT_ADDENDUM_CREATE_cc IS TABLE OF PN_AREA.STEXT_ADDENDUM_CREATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "STEXT_ADDENDUM_CANCEL"
   TYPE STEXT_ADDENDUM_CANCEL_cc IS TABLE OF PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "STEXT_NOTE_CANCEL"
   TYPE STEXT_NOTE_CANCEL_cc IS TABLE OF PN_AREA.STEXT_NOTE_CANCEL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_REPORT"
   TYPE ID_REPORT_cc IS TABLE OF PN_AREA.ID_REPORT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_TASK"
   TYPE FLG_TASK_cc IS TABLE OF PN_AREA.FLG_TASK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CATEGORY"
   TYPE ID_CATEGORY_cc IS TABLE OF PN_AREA.ID_CATEGORY%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SYS_SHORTCUT"
   TYPE ID_SYS_SHORTCUT_cc IS TABLE OF PN_AREA.ID_SYS_SHORTCUT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "RANK"
   TYPE RANK_cc IS TABLE OF PN_AREA.RANK%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
      ,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
      ,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PN_AREA%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PN_AREA%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PN_AREA_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PN_AREA_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PN_AREA.ID_PN_AREA%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      id_pn_area_out IN OUT PN_AREA.ID_PN_AREA%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      id_pn_area_out IN OUT PN_AREA.ID_PN_AREA%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PN_AREA.ID_PN_AREA%TYPE
      ;

   FUNCTION ins (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PN_AREA.ID_PN_AREA%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      INTERNAL_NAME_nin IN BOOLEAN := TRUE,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      CODE_PN_AREA_nin IN BOOLEAN := TRUE,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      SCREEN_NAME_nin IN BOOLEAN := TRUE,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      CANCEL_REASON_NOTE_nin IN BOOLEAN := TRUE,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      CANCEL_REASON_ADDENDUM_nin IN BOOLEAN := TRUE,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CREATE_nin IN BOOLEAN := TRUE,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CANCEL_nin IN BOOLEAN := TRUE,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      STEXT_NOTE_CANCEL_nin IN BOOLEAN := TRUE,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      ID_REPORT_nin IN BOOLEAN := TRUE,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      FLG_TASK_nin IN BOOLEAN := TRUE,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      ID_CATEGORY_nin IN BOOLEAN := TRUE,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      ID_SYS_SHORTCUT_nin IN BOOLEAN := TRUE,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      INTERNAL_NAME_nin IN BOOLEAN := TRUE,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      CODE_PN_AREA_nin IN BOOLEAN := TRUE,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      SCREEN_NAME_nin IN BOOLEAN := TRUE,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      CANCEL_REASON_NOTE_nin IN BOOLEAN := TRUE,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      CANCEL_REASON_ADDENDUM_nin IN BOOLEAN := TRUE,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CREATE_nin IN BOOLEAN := TRUE,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CANCEL_nin IN BOOLEAN := TRUE,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      STEXT_NOTE_CANCEL_nin IN BOOLEAN := TRUE,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      ID_REPORT_nin IN BOOLEAN := TRUE,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      FLG_TASK_nin IN BOOLEAN := TRUE,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      ID_CATEGORY_nin IN BOOLEAN := TRUE,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      ID_SYS_SHORTCUT_nin IN BOOLEAN := TRUE,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      INTERNAL_NAME_nin IN BOOLEAN := TRUE,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      CODE_PN_AREA_nin IN BOOLEAN := TRUE,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      SCREEN_NAME_nin IN BOOLEAN := TRUE,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      CANCEL_REASON_NOTE_nin IN BOOLEAN := TRUE,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      CANCEL_REASON_ADDENDUM_nin IN BOOLEAN := TRUE,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CREATE_nin IN BOOLEAN := TRUE,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CANCEL_nin IN BOOLEAN := TRUE,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      STEXT_NOTE_CANCEL_nin IN BOOLEAN := TRUE,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      ID_REPORT_nin IN BOOLEAN := TRUE,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      FLG_TASK_nin IN BOOLEAN := TRUE,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      ID_CATEGORY_nin IN BOOLEAN := TRUE,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      ID_SYS_SHORTCUT_nin IN BOOLEAN := TRUE,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      INTERNAL_NAME_nin IN BOOLEAN := TRUE,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      CODE_PN_AREA_nin IN BOOLEAN := TRUE,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      SCREEN_NAME_nin IN BOOLEAN := TRUE,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      CANCEL_REASON_NOTE_nin IN BOOLEAN := TRUE,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      CANCEL_REASON_ADDENDUM_nin IN BOOLEAN := TRUE,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CREATE_nin IN BOOLEAN := TRUE,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      STEXT_ADDENDUM_CANCEL_nin IN BOOLEAN := TRUE,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      STEXT_NOTE_CANCEL_nin IN BOOLEAN := TRUE,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      ID_REPORT_nin IN BOOLEAN := TRUE,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      FLG_TASK_nin IN BOOLEAN := TRUE,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      ID_CATEGORY_nin IN BOOLEAN := TRUE,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      ID_SYS_SHORTCUT_nin IN BOOLEAN := TRUE,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE,
      internal_name_in IN PN_AREA.INTERNAL_NAME%TYPE DEFAULT NULL,
      code_pn_area_in IN PN_AREA.CODE_PN_AREA%TYPE DEFAULT NULL,
      screen_name_in IN PN_AREA.SCREEN_NAME%TYPE DEFAULT NULL,
      create_user_in IN PN_AREA.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PN_AREA.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PN_AREA.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PN_AREA.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PN_AREA.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PN_AREA.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      cancel_reason_note_in IN PN_AREA.CANCEL_REASON_NOTE%TYPE DEFAULT NULL,
      cancel_reason_addendum_in IN PN_AREA.CANCEL_REASON_ADDENDUM%TYPE DEFAULT NULL,
      stext_addendum_create_in IN PN_AREA.STEXT_ADDENDUM_CREATE%TYPE DEFAULT NULL,
      stext_addendum_cancel_in IN PN_AREA.STEXT_ADDENDUM_CANCEL%TYPE DEFAULT NULL,
      stext_note_cancel_in IN PN_AREA.STEXT_NOTE_CANCEL%TYPE DEFAULT NULL,
      id_report_in IN PN_AREA.ID_REPORT%TYPE DEFAULT NULL,
      flg_task_in IN PN_AREA.FLG_TASK%TYPE DEFAULT NULL,
      id_category_in IN PN_AREA.ID_CATEGORY%TYPE DEFAULT NULL,
      id_sys_shortcut_in IN PN_AREA.ID_SYS_SHORTCUT%TYPE DEFAULT NULL,
      rank_in IN PN_AREA.RANK%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PN_AREA%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PN_AREA%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PN_AREA_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PN_AREA_tc,
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
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PN_AREA
   PROCEDURE del_ID_PN_AREA (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PN_AREA
   PROCEDURE del_ID_PN_AREA (
      id_pn_area_in IN PN_AREA.ID_PN_AREA%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this PA_REP_FK foreign key value
   PROCEDURE del_PA_REP_FK (
      id_report_in IN PN_AREA.ID_REPORT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PA_REP_FK foreign key value
   PROCEDURE del_PA_REP_FK (
      id_report_in IN PN_AREA.ID_REPORT%TYPE
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
      pn_area_inout IN OUT PN_AREA%ROWTYPE
   );

   FUNCTION initrec RETURN PN_AREA%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PN_AREA_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PN_AREA_tc;

END TS_PN_AREA;
/
