/*-- Last Change Revision: $Rev: 1658071 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 09:49:40 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE TS_NNN_EPIS_LNK_OUTC_IND
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 8, 2014 10:35:7
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NNN_EPIS_LNK_OUTC_IND"
     TYPE NNN_EPIS_LNK_OUTC_IND_tc IS TABLE OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nnn_epis_lnk_outc_ind_ntt IS TABLE OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE;
     TYPE nnn_epis_lnk_outc_ind_vat IS VARRAY(100) OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NNN_EPIS_LNK_OUTC_IND%ROWTYPE;

   -- Column Collection based on column "ID_NNN_EPIS_LNK_OUTC_IND"
   TYPE ID_NNN_EPIS_LNK_OUTC_IND_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NNN_EPIS_OUTCOME"
   TYPE ID_NNN_EPIS_OUTCOME_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NNN_EPIS_INDICATOR"
   TYPE ID_NNN_EPIS_INDICATOR_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "OUTCOME_INDICATOR_CODE"
   TYPE OUTCOME_INDICATOR_CODE_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_LNK_STATUS"
   TYPE FLG_LNK_STATUS_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_TRS_TIME_START"
   TYPE DT_TRS_TIME_START_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_TRS_TIME_END"
   TYPE DT_TRS_TIME_END_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      ,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      ,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NNN_EPIS_LNK_OUTC_IND%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NNN_EPIS_LNK_OUTC_IND%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NNN_EPIS_LNK_OUTC_IND_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NNN_EPIS_LNK_OUTC_IND_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_lnk_outc_ind_out IN OUT NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nnn_epis_lnk_outc_ind_out IN OUT NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      ;

   FUNCTION ins (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      ID_NNN_EPIS_OUTCOME_nin IN BOOLEAN := TRUE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      ID_NNN_EPIS_INDICATOR_nin IN BOOLEAN := TRUE,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      OUTCOME_INDICATOR_CODE_nin IN BOOLEAN := TRUE,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      FLG_LNK_STATUS_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      DT_TRS_TIME_END_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      ID_NNN_EPIS_OUTCOME_nin IN BOOLEAN := TRUE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      ID_NNN_EPIS_INDICATOR_nin IN BOOLEAN := TRUE,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      OUTCOME_INDICATOR_CODE_nin IN BOOLEAN := TRUE,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      FLG_LNK_STATUS_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      DT_TRS_TIME_END_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      ID_NNN_EPIS_OUTCOME_nin IN BOOLEAN := TRUE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      ID_NNN_EPIS_INDICATOR_nin IN BOOLEAN := TRUE,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      OUTCOME_INDICATOR_CODE_nin IN BOOLEAN := TRUE,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      FLG_LNK_STATUS_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      DT_TRS_TIME_END_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      ID_NNN_EPIS_OUTCOME_nin IN BOOLEAN := TRUE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      ID_NNN_EPIS_INDICATOR_nin IN BOOLEAN := TRUE,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      OUTCOME_INDICATOR_CODE_nin IN BOOLEAN := TRUE,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      FLG_LNK_STATUS_nin IN BOOLEAN := TRUE,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      DT_TRS_TIME_START_nin IN BOOLEAN := TRUE,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      DT_TRS_TIME_END_nin IN BOOLEAN := TRUE,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE,
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE DEFAULT NULL,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE DEFAULT NULL,
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      outcome_indicator_code_in IN NNN_EPIS_LNK_OUTC_IND.OUTCOME_INDICATOR_CODE%TYPE DEFAULT NULL,
      flg_lnk_status_in IN NNN_EPIS_LNK_OUTC_IND.FLG_LNK_STATUS%TYPE DEFAULT NULL,
      dt_trs_time_start_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_START%TYPE DEFAULT NULL,
      dt_trs_time_end_in IN NNN_EPIS_LNK_OUTC_IND.DT_TRS_TIME_END%TYPE DEFAULT NULL,
      create_user_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NNN_EPIS_LNK_OUTC_IND.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NNN_EPIS_LNK_OUTC_IND.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NNN_EPIS_LNK_OUTC_IND%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NNN_EPIS_LNK_OUTC_IND%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_LNK_OUTC_IND_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NNN_EPIS_LNK_OUTC_IND_tc,
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
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NNN_EPIS_LNK_OUTC_IND
   PROCEDURE del_ID_NNN_EPIS_LNK_OUTC_IND (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NNN_EPIS_LNK_OUTC_IND
   PROCEDURE del_ID_NNN_EPIS_LNK_OUTC_IND (
      id_nnn_epis_lnk_outc_ind_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_LNK_OUTC_IND%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of NNN_EPIS_LNK_OUTC_IND_UK
   PROCEDURE del_NNN_EPIS_LNK_OUTC_IND_UK (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of NNN_EPIS_LNK_OUTC_IND_UK
   PROCEDURE del_NNN_EPIS_LNK_OUTC_IND_UK (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE,
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNELOI_EPIS_FK foreign key value
   PROCEDURE del_NNNELOI_EPIS_FK (
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNELOI_EPIS_FK foreign key value
   PROCEDURE del_NNNELOI_EPIS_FK (
      id_episode_in IN NNN_EPIS_LNK_OUTC_IND.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNELOI_NNNEI_FK foreign key value
   PROCEDURE del_NNNELOI_NNNEI_FK (
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNELOI_NNNEI_FK foreign key value
   PROCEDURE del_NNNELOI_NNNEI_FK (
      id_nnn_epis_indicator_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_INDICATOR%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNELOI_NNNEO_FK foreign key value
   PROCEDURE del_NNNELOI_NNNEO_FK (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNELOI_NNNEO_FK foreign key value
   PROCEDURE del_NNNELOI_NNNEO_FK (
      id_nnn_epis_outcome_in IN NNN_EPIS_LNK_OUTC_IND.ID_NNN_EPIS_OUTCOME%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NNNELOI_PROF_FK foreign key value
   PROCEDURE del_NNNELOI_PROF_FK (
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NNNELOI_PROF_FK foreign key value
   PROCEDURE del_NNNELOI_PROF_FK (
      id_professional_in IN NNN_EPIS_LNK_OUTC_IND.ID_PROFESSIONAL%TYPE
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
      nnn_epis_lnk_outc_ind_inout IN OUT NNN_EPIS_LNK_OUTC_IND%ROWTYPE
   );

   FUNCTION initrec RETURN NNN_EPIS_LNK_OUTC_IND%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_LNK_OUTC_IND_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NNN_EPIS_LNK_OUTC_IND_tc;

END TS_NNN_EPIS_LNK_OUTC_IND;
/
