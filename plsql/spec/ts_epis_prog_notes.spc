/*-- Last Change Revision: $Rev: 792943 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2010-12-02 17:48:34 +0000 (qui, 02 dez 2010) $*/


CREATE OR REPLACE PACKAGE TS_EPIS_PROG_NOTES
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 20, 2010 10:39:8
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "EPIS_PROG_NOTES"
     TYPE EPIS_PROG_NOTES_tc IS TABLE OF EPIS_PROG_NOTES%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE epis_prog_notes_ntt IS TABLE OF EPIS_PROG_NOTES%ROWTYPE;
     TYPE epis_prog_notes_vat IS VARRAY(100) OF EPIS_PROG_NOTES%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF EPIS_PROG_NOTES%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF EPIS_PROG_NOTES%ROWTYPE;
     TYPE vat IS VARRAY(100) OF EPIS_PROG_NOTES%ROWTYPE;

   -- Column Collection based on column "ID_EPIS_PROG_NOTES"
   TYPE ID_EPIS_PROG_NOTES_cc IS TABLE OF EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF EPIS_PROG_NOTES.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PN_SOAP_BLOCK"
   TYPE ID_PN_SOAP_BLOCK_cc IS TABLE OF EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF EPIS_PROG_NOTES.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TEXT"
   TYPE TEXT_cc IS TABLE OF EPIS_PROG_NOTES.TEXT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CREATED"
   TYPE ID_PROF_CREATED_cc IS TABLE OF EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATED"
   TYPE DT_CREATED_cc IS TABLE OF EPIS_PROG_NOTES.DT_CREATED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_LAST_UPDATE"
   TYPE ID_PROF_LAST_UPDATE_cc IS TABLE OF EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_LAST_UPDATE"
   TYPE DT_LAST_UPDATE_cc IS TABLE OF EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_INFO_DET"
   TYPE ID_CANCEL_INFO_DET_cc IS TABLE OF EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPN_PARENT"
   TYPE ID_EPN_PARENT_cc IS TABLE OF EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF EPIS_PROG_NOTES.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF EPIS_PROG_NOTES.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF EPIS_PROG_NOTES.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF EPIS_PROG_NOTES.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
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
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      ,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      ,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN EPIS_PROG_NOTES%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN EPIS_PROG_NOTES%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN EPIS_PROG_NOTES_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN EPIS_PROG_NOTES_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_epis_prog_notes_out IN OUT EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_epis_prog_notes_out IN OUT EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      ;

   FUNCTION ins (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      ID_PROF_CREATED_nin IN BOOLEAN := TRUE,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      ID_EPN_PARENT_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      ID_PROF_CREATED_nin IN BOOLEAN := TRUE,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      ID_EPN_PARENT_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      ID_PROF_CREATED_nin IN BOOLEAN := TRUE,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      ID_EPN_PARENT_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      TEXT_nin IN BOOLEAN := TRUE,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      ID_PROF_CREATED_nin IN BOOLEAN := TRUE,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      ID_EPN_PARENT_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE,
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_PROG_NOTES.FLG_STATUS%TYPE DEFAULT NULL,
      text_in IN EPIS_PROG_NOTES.TEXT%TYPE DEFAULT NULL,
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE DEFAULT NULL,
      dt_created_in IN EPIS_PROG_NOTES.DT_CREATED%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PROG_NOTES.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PROG_NOTES.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PROG_NOTES.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PROG_NOTES.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PROG_NOTES.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PROG_NOTES.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PROG_NOTES.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN EPIS_PROG_NOTES%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN EPIS_PROG_NOTES%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN EPIS_PROG_NOTES_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN EPIS_PROG_NOTES_tc,
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
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_EPIS_PROG_NOTES
   PROCEDURE del_ID_EPIS_PROG_NOTES (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_EPIS_PROG_NOTES
   PROCEDURE del_ID_EPIS_PROG_NOTES (
      id_epis_prog_notes_in IN EPIS_PROG_NOTES.ID_EPIS_PROG_NOTES%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this EPN_CID_FK foreign key value
   PROCEDURE del_EPN_CID_FK (
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_CID_FK foreign key value
   PROCEDURE del_EPN_CID_FK (
      id_cancel_info_det_in IN EPIS_PROG_NOTES.ID_CANCEL_INFO_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPN_EPIS_FK foreign key value
   PROCEDURE del_EPN_EPIS_FK (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_EPIS_FK foreign key value
   PROCEDURE del_EPN_EPIS_FK (
      id_episode_in IN EPIS_PROG_NOTES.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPN_EPN_FK foreign key value
   PROCEDURE del_EPN_EPN_FK (
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_EPN_FK foreign key value
   PROCEDURE del_EPN_EPN_FK (
      id_epn_parent_in IN EPIS_PROG_NOTES.ID_EPN_PARENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPN_PNSB_FK foreign key value
   PROCEDURE del_EPN_PNSB_FK (
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_PNSB_FK foreign key value
   PROCEDURE del_EPN_PNSB_FK (
      id_pn_soap_block_in IN EPIS_PROG_NOTES.ID_PN_SOAP_BLOCK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPN_PROF_CREATED_FK foreign key value
   PROCEDURE del_EPN_PROF_CREATED_FK (
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_PROF_CREATED_FK foreign key value
   PROCEDURE del_EPN_PROF_CREATED_FK (
      id_prof_created_in IN EPIS_PROG_NOTES.ID_PROF_CREATED%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPN_PROF_LAST_UPD_FK foreign key value
   PROCEDURE del_EPN_PROF_LAST_UPD_FK (
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPN_PROF_LAST_UPD_FK foreign key value
   PROCEDURE del_EPN_PROF_LAST_UPD_FK (
      id_prof_last_update_in IN EPIS_PROG_NOTES.ID_PROF_LAST_UPDATE%TYPE
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
      epis_prog_notes_inout IN OUT EPIS_PROG_NOTES%ROWTYPE
   );

   FUNCTION initrec RETURN EPIS_PROG_NOTES%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_PROG_NOTES_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_PROG_NOTES_tc;

END TS_EPIS_PROG_NOTES;
/
