/*-- Last Change Revision: $Rev: 2029161 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE ts_epis_interv_plan_hist IS

  -- Collection of %ROWTYPE records based on "EPIS_INTERV_PLAN_HIST"
     TYPE EPIS_INTERV_PLAN_HIST_tc IS TABLE OF EPIS_INTERV_PLAN_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE epis_interv_plan_hist_ntt IS TABLE OF EPIS_INTERV_PLAN_HIST%ROWTYPE;
     TYPE epis_interv_plan_hist_vat IS VARRAY(100) OF EPIS_INTERV_PLAN_HIST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF EPIS_INTERV_PLAN_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF EPIS_INTERV_PLAN_HIST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF EPIS_INTERV_PLAN_HIST%ROWTYPE;

   -- Column Collection based on column "ID_EPIS_INTERV_PLAN_HIST"
   TYPE ID_EPIS_INTERV_PLAN_HIST_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPIS_INTERV_PLAN"
   TYPE ID_EPIS_INTERV_PLAN_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INTERV_PLAN"
   TYPE ID_INTERV_PLAN_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "NOTES"
   TYPE NOTES_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.NOTES%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION"
   TYPE DT_CREATION_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_BEGIN"
   TYPE DT_BEGIN_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_END"
   TYPE DT_END_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.DT_END%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_INFO_DET"
   TYPE ID_CANCEL_INFO_DET_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_AVAILABLE"
   TYPE FLG_AVAILABLE_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DESC_OTHER_INTERV_PLAN"
   TYPE DESC_OTHER_INTERV_PLAN_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_TASK_GOAL_DET"
   TYPE ID_TASK_GOAL_DET_cc IS TABLE OF EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      ,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      ,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN EPIS_INTERV_PLAN_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN EPIS_INTERV_PLAN_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN EPIS_INTERV_PLAN_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN EPIS_INTERV_PLAN_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_epis_interv_plan_hist_out IN OUT EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_epis_interv_plan_hist_out IN OUT EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      ;

   FUNCTION ins (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_EPIS_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_EPIS_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_EPIS_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_EPIS_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      ID_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      DT_BEGIN_nin IN BOOLEAN := TRUE,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      DT_END_nin IN BOOLEAN := TRUE,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      ID_CANCEL_INFO_DET_nin IN BOOLEAN := TRUE,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      DESC_OTHER_INTERV_PLAN_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE,
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE DEFAULT NULL,
      id_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_INTERV_PLAN%TYPE DEFAULT NULL,
      id_episode_in IN EPIS_INTERV_PLAN_HIST.ID_EPISODE%TYPE DEFAULT NULL,
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_INTERV_PLAN_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN EPIS_INTERV_PLAN_HIST.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN EPIS_INTERV_PLAN_HIST.DT_CREATION%TYPE DEFAULT NULL,
      dt_begin_in IN EPIS_INTERV_PLAN_HIST.DT_BEGIN%TYPE DEFAULT NULL,
      dt_end_in IN EPIS_INTERV_PLAN_HIST.DT_END%TYPE DEFAULT NULL,
      id_cancel_info_det_in IN EPIS_INTERV_PLAN_HIST.ID_CANCEL_INFO_DET%TYPE DEFAULT NULL,
      flg_available_in IN EPIS_INTERV_PLAN_HIST.FLG_AVAILABLE%TYPE DEFAULT NULL,
      desc_other_interv_plan_in IN EPIS_INTERV_PLAN_HIST.DESC_OTHER_INTERV_PLAN%TYPE DEFAULT NULL,
      create_user_in IN EPIS_INTERV_PLAN_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_INTERV_PLAN_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_INTERV_PLAN_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_INTERV_PLAN_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_INTERV_PLAN_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_INTERV_PLAN_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN EPIS_INTERV_PLAN_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN EPIS_INTERV_PLAN_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN EPIS_INTERV_PLAN_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN EPIS_INTERV_PLAN_HIST_tc,
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
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_EPIS_INTERV_PLAN_HIST
   PROCEDURE del_ID_EPIS_INTERV_PLAN_HIST (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_EPIS_INTERV_PLAN_HIST
   PROCEDURE del_ID_EPIS_INTERV_PLAN_HIST (
      id_epis_interv_plan_hist_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this EIPH_EIH_FK foreign key value
   PROCEDURE del_EIPH_EIH_FK (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EIPH_EIH_FK foreign key value
   PROCEDURE del_EIPH_EIH_FK (
      id_epis_interv_plan_in IN EPIS_INTERV_PLAN_HIST.ID_EPIS_INTERV_PLAN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EIPH_P_FK foreign key value
   PROCEDURE del_EIPH_P_FK (
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EIPH_P_FK foreign key value
   PROCEDURE del_EIPH_P_FK (
      id_professional_in IN EPIS_INTERV_PLAN_HIST.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EIPH_TSKGD_FK foreign key value
   PROCEDURE del_EIPH_TSKGD_FK (
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EIPH_TSKGD_FK foreign key value
   PROCEDURE del_EIPH_TSKGD_FK (
      id_task_goal_det_in IN EPIS_INTERV_PLAN_HIST.ID_TASK_GOAL_DET%TYPE
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
      epis_interv_plan_hist_inout IN OUT EPIS_INTERV_PLAN_HIST%ROWTYPE
   );

   FUNCTION initrec RETURN EPIS_INTERV_PLAN_HIST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_INTERV_PLAN_HIST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_INTERV_PLAN_HIST_tc;

END ts_epis_interv_plan_hist;
/
