/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_NNN_EPIS_ACTV_DET_TSKH
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: September 9, 2014 17:7:59
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NNN_EPIS_ACTV_DET_TSKH"
     TYPE NNN_EPIS_ACTV_DET_TSKH_tc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nnn_epis_actv_det_tskh_ntt IS TABLE OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE;
     TYPE nnn_epis_actv_det_tskh_vat IS VARRAY(100) OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NNN_EPIS_ACTV_DET_TSKH%ROWTYPE;

   -- Column Collection based on column "ID_NNN_EPIS_ACTV_DET_TSKH"
   TYPE ID_NNN_EPIS_ACTV_DET_TSKH_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NNN_EPIS_ACTIVITY_DET"
   TYPE ID_NNN_EPIS_ACTIVITY_DET_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_TRS_TIME_START"
   TYPE DT_TRS_TIME_START_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NIC_ACTIVITY"
   TYPE ID_NIC_ACTIVITY_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_EXECUTED"
   TYPE FLG_EXECUTED_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "NOTES"
   TYPE NOTES_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
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
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      ,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      ,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NNN_EPIS_ACTV_DET_TSKH%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NNN_EPIS_ACTV_DET_TSKH%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NNN_EPIS_ACTV_DET_TSKH_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NNN_EPIS_ACTV_DET_TSKH_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_actv_det_tskh_out IN OUT NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_actv_det_tskh_out IN OUT NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      ;

   FUNCTION ins (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      ID_NNN_EPIS_ACTIVITY_DET_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      ID_NIC_ACTIVITY_nin IN BOOLEAN := TRUE,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      FLG_EXECUTED_nin IN BOOLEAN := TRUE,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      ID_NNN_EPIS_ACTIVITY_DET_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      ID_NIC_ACTIVITY_nin IN BOOLEAN := TRUE,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      FLG_EXECUTED_nin IN BOOLEAN := TRUE,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      ID_NNN_EPIS_ACTIVITY_DET_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      ID_NIC_ACTIVITY_nin IN BOOLEAN := TRUE,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      FLG_EXECUTED_nin IN BOOLEAN := TRUE,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      ID_NNN_EPIS_ACTIVITY_DET_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      ID_NIC_ACTIVITY_nin IN BOOLEAN := TRUE,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      FLG_EXECUTED_nin IN BOOLEAN := TRUE,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE,
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      id_nic_activity_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NIC_ACTIVITY%TYPE DEFAULT NULL,
      flg_executed_in IN NNN_EPIS_ACTV_DET_TSKH.FLG_EXECUTED%TYPE DEFAULT NULL,
      notes_in IN NNN_EPIS_ACTV_DET_TSKH.NOTES%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_ACTV_DET_TSKH.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_ACTV_DET_TSKH.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NNN_EPIS_ACTV_DET_TSKH%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NNN_EPIS_ACTV_DET_TSKH%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_ACTV_DET_TSKH_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_ACTV_DET_TSKH_tc,
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
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NNN_EPIS_ACTV_DET_TSKH
   PROCEDURE del_ID_NNN_EPIS_ACTV_DET_TSKH (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NNN_EPIS_ACTV_DET_TSKH
   PROCEDURE del_ID_NNN_EPIS_ACTV_DET_TSKH (
      id_nnn_epis_actv_det_tskh_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTV_DET_TSKH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   
   -- Delete all rows for this NNNEADTH_NNNEADH_FK foreign key value
   PROCEDURE del_NNNEADTH_NNNEADH_FK (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNEADTH_NNNEADH_FK foreign key value
   PROCEDURE del_NNNEADTH_NNNEADH_FK (
      id_nnn_epis_activity_det_in IN NNN_EPIS_ACTV_DET_TSKH.ID_NNN_EPIS_ACTIVITY_DET%TYPE,
      dt_trs_time_start_in IN NNN_EPIS_ACTV_DET_TSKH.DT_TRS_TIME_START%TYPE
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
      nnn_epis_actv_det_tskh_inout IN OUT NNN_EPIS_ACTV_DET_TSKH%ROWTYPE
   );

   FUNCTION initrec RETURN NNN_EPIS_ACTV_DET_TSKH%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_ACTV_DET_TSKH_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_ACTV_DET_TSKH_tc;

END TS_NNN_EPIS_ACTV_DET_TSKH;
/
