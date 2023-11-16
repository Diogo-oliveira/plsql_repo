/*-- Last Change Revision: $Rev: 447377 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2010-03-23 08:56:28 +0000 (ter, 23 mar 2010) $*/


CREATE OR REPLACE PACKAGE TS_PARAMED_REPORT
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Março 19, 2010 13:37:52
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PARAMED_REPORT"
     TYPE PARAMED_REPORT_tc IS TABLE OF PARAMED_REPORT%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE paramed_report_ntt IS TABLE OF PARAMED_REPORT%ROWTYPE;
     TYPE paramed_report_vat IS VARRAY(100) OF PARAMED_REPORT%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PARAMED_REPORT%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PARAMED_REPORT%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PARAMED_REPORT%ROWTYPE;

   -- Column Collection based on column "ID_PARAMED_REPORT"
   TYPE ID_PARAMED_REPORT_cc IS TABLE OF PARAMED_REPORT.ID_PARAMED_REPORT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF PARAMED_REPORT.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TEXT"
   TYPE TEXT_cc IS TABLE OF PARAMED_REPORT.TEXT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF PARAMED_REPORT.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION"
   TYPE DT_CREATION_cc IS TABLE OF PARAMED_REPORT.DT_CREATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_LAST_UPDATE"
   TYPE DT_LAST_UPDATE_cc IS TABLE OF PARAMED_REPORT.DT_LAST_UPDATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF PARAMED_REPORT.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_INFO_DET"
   TYPE ID_CANCEL_INFO_DET_cc IS TABLE OF PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PARAMED_REPORT.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PARAMED_REPORT.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PARAMED_REPORT.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PARAMED_REPORT.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PARAMED_REPORT.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PARAMED_REPORT.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN DEFAULT TRUE,
      handle_error_in IN BOOLEAN DEFAULT TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   /*
   END Special logic for handling LOB columns.
   */
   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      ,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      ,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PARAMED_REPORT%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PARAMED_REPORT%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PARAMED_REPORT_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PARAMED_REPORT_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_paramed_report_out IN OUT PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_paramed_report_out IN OUT PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      ;

   FUNCTION ins (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE,
      flg_status_in IN PARAMED_REPORT.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN PARAMED_REPORT.TEXT%TYPE DEFAULT NULL,
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE DEFAULT NULL,
      dt_creation_in IN PARAMED_REPORT.DT_CREATION%TYPE DEFAULT NULL,
      dt_last_update_in IN PARAMED_REPORT.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      create_user_in IN PARAMED_REPORT.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PARAMED_REPORT.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PARAMED_REPORT.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PARAMED_REPORT.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PARAMED_REPORT.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PARAMED_REPORT.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PARAMED_REPORT%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PARAMED_REPORT%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PARAMED_REPORT_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PARAMED_REPORT_tc,
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
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PARAMED_REPORT
   PROCEDURE del_ID_PARAMED_REPORT (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PARAMED_REPORT
   PROCEDURE del_ID_PARAMED_REPORT (
      id_paramed_report_in IN PARAMED_REPORT.ID_PARAMED_REPORT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this PMR_CID_FK foreign key value
   PROCEDURE del_PMR_CID_FK (
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMR_CID_FK foreign key value
   PROCEDURE del_PMR_CID_FK (
      id_cancel_info_det_in IN PARAMED_REPORT.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMR_EPIS_FK foreign key value
   PROCEDURE del_PMR_EPIS_FK (
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMR_EPIS_FK foreign key value
   PROCEDURE del_PMR_EPIS_FK (
      id_episode_in IN PARAMED_REPORT.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PMR_PROF_FK foreign key value
   PROCEDURE del_PMR_PROF_FK (
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PMR_PROF_FK foreign key value
   PROCEDURE del_PMR_PROF_FK (
      id_professional_in IN PARAMED_REPORT.ID_PROFESSIONAL%TYPE
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
      paramed_report_inout IN OUT PARAMED_REPORT%ROWTYPE
   );

   FUNCTION initrec RETURN PARAMED_REPORT%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PARAMED_REPORT_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PARAMED_REPORT_tc;

END TS_PARAMED_REPORT;
/