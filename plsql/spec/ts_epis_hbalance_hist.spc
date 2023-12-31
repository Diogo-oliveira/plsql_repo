/*-- Last Change Revision: $Rev: 2029147 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:03 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE TS_EPIS_HBALANCE_HIST
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: April 12, 2016 14:22:14
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "EPIS_HBALANCE_HIST"
     TYPE EPIS_HBALANCE_HIST_tc IS TABLE OF EPIS_HBALANCE_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE epis_hbalance_hist_ntt IS TABLE OF EPIS_HBALANCE_HIST%ROWTYPE;
     TYPE epis_hbalance_hist_vat IS VARRAY(100) OF EPIS_HBALANCE_HIST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF EPIS_HBALANCE_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF EPIS_HBALANCE_HIST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF EPIS_HBALANCE_HIST%ROWTYPE;

   -- Column Collection based on column "ID_EPIS_HIDRICS_BALANCE"
   TYPE ID_EPIS_HIDRICS_BALANCE_cc IS TABLE OF EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_EPIS_HBALANCE_HIST"
   TYPE DT_EPIS_HBALANCE_HIST_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPIS_HIDRICS"
   TYPE ID_EPIS_HIDRICS_cc IS TABLE OF EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CLOSE"
   TYPE ID_PROF_CLOSE_cc IS TABLE OF EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF EPIS_HBALANCE_HIST.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TOTAL_ADMIN"
   TYPE TOTAL_ADMIN_cc IS TABLE OF EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TOTAL_ELIM"
   TYPE TOTAL_ELIM_cc IS TABLE OF EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_UNIT_MEASURE"
   TYPE ID_UNIT_MEASURE_cc IS TABLE OF EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_PREV_CLOSE_TSTZ"
   TYPE DT_PREV_CLOSE_TSTZ_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CLOSE_BALANCE_TSTZ"
   TYPE DT_CLOSE_BALANCE_TSTZ_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_OPEN_TSTZ"
   TYPE DT_OPEN_TSTZ_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_REGISTER_TSTZ"
   TYPE DT_REGISTER_TSTZ_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF EPIS_HBALANCE_HIST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF EPIS_HBALANCE_HIST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF EPIS_HBALANCE_HIST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_LAST_CHANGE"
   TYPE ID_PROF_LAST_CHANGE_cc IS TABLE OF EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_EH_BALANCE"
   TYPE DT_EH_BALANCE_cc IS TABLE OF EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_CLOSE_TYPE"
   TYPE FLG_CLOSE_TYPE_cc IS TABLE OF EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TOTAL_TIMES"
   TYPE TOTAL_TIMES_cc IS TABLE OF EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
      ,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
      ,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN EPIS_HBALANCE_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN EPIS_HBALANCE_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN EPIS_HBALANCE_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN EPIS_HBALANCE_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      ID_EPIS_HIDRICS_nin IN BOOLEAN := TRUE,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      ID_PROF_CLOSE_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      TOTAL_ADMIN_nin IN BOOLEAN := TRUE,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      TOTAL_ELIM_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      DT_PREV_CLOSE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      DT_CLOSE_BALANCE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      DT_OPEN_TSTZ_nin IN BOOLEAN := TRUE,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      DT_REGISTER_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      ID_PROF_LAST_CHANGE_nin IN BOOLEAN := TRUE,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      DT_EH_BALANCE_nin IN BOOLEAN := TRUE,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      FLG_CLOSE_TYPE_nin IN BOOLEAN := TRUE,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
      TOTAL_TIMES_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      ID_EPIS_HIDRICS_nin IN BOOLEAN := TRUE,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      ID_PROF_CLOSE_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      TOTAL_ADMIN_nin IN BOOLEAN := TRUE,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      TOTAL_ELIM_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      DT_PREV_CLOSE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      DT_CLOSE_BALANCE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      DT_OPEN_TSTZ_nin IN BOOLEAN := TRUE,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      DT_REGISTER_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      ID_PROF_LAST_CHANGE_nin IN BOOLEAN := TRUE,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      DT_EH_BALANCE_nin IN BOOLEAN := TRUE,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      FLG_CLOSE_TYPE_nin IN BOOLEAN := TRUE,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
      TOTAL_TIMES_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      ID_EPIS_HIDRICS_nin IN BOOLEAN := TRUE,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      ID_PROF_CLOSE_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      TOTAL_ADMIN_nin IN BOOLEAN := TRUE,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      TOTAL_ELIM_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      DT_PREV_CLOSE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      DT_CLOSE_BALANCE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      DT_OPEN_TSTZ_nin IN BOOLEAN := TRUE,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      DT_REGISTER_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      ID_PROF_LAST_CHANGE_nin IN BOOLEAN := TRUE,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      DT_EH_BALANCE_nin IN BOOLEAN := TRUE,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      FLG_CLOSE_TYPE_nin IN BOOLEAN := TRUE,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
      TOTAL_TIMES_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      ID_EPIS_HIDRICS_nin IN BOOLEAN := TRUE,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      ID_PROF_CLOSE_nin IN BOOLEAN := TRUE,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      TOTAL_ADMIN_nin IN BOOLEAN := TRUE,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      TOTAL_ELIM_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      DT_PREV_CLOSE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      DT_CLOSE_BALANCE_TSTZ_nin IN BOOLEAN := TRUE,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      DT_OPEN_TSTZ_nin IN BOOLEAN := TRUE,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      DT_REGISTER_TSTZ_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      ID_PROF_LAST_CHANGE_nin IN BOOLEAN := TRUE,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      DT_EH_BALANCE_nin IN BOOLEAN := TRUE,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      FLG_CLOSE_TYPE_nin IN BOOLEAN := TRUE,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
      TOTAL_TIMES_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE,
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE DEFAULT NULL,
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE DEFAULT NULL,
      flg_status_in IN EPIS_HBALANCE_HIST.FLG_STATUS%TYPE DEFAULT NULL,
      total_admin_in IN EPIS_HBALANCE_HIST.TOTAL_ADMIN%TYPE DEFAULT NULL,
      total_elim_in IN EPIS_HBALANCE_HIST.TOTAL_ELIM%TYPE DEFAULT NULL,
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      dt_prev_close_tstz_in IN EPIS_HBALANCE_HIST.DT_PREV_CLOSE_TSTZ%TYPE DEFAULT NULL,
      dt_close_balance_tstz_in IN EPIS_HBALANCE_HIST.DT_CLOSE_BALANCE_TSTZ%TYPE DEFAULT NULL,
      dt_open_tstz_in IN EPIS_HBALANCE_HIST.DT_OPEN_TSTZ%TYPE DEFAULT NULL,
      dt_register_tstz_in IN EPIS_HBALANCE_HIST.DT_REGISTER_TSTZ%TYPE DEFAULT NULL,
      create_user_in IN EPIS_HBALANCE_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_HBALANCE_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_HBALANCE_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_HBALANCE_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_HBALANCE_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_HBALANCE_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE DEFAULT NULL,
      dt_eh_balance_in IN EPIS_HBALANCE_HIST.DT_EH_BALANCE%TYPE DEFAULT NULL,
      flg_close_type_in IN EPIS_HBALANCE_HIST.FLG_CLOSE_TYPE%TYPE DEFAULT NULL,
      total_times_in IN EPIS_HBALANCE_HIST.TOTAL_TIMES%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN EPIS_HBALANCE_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN EPIS_HBALANCE_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN EPIS_HBALANCE_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN EPIS_HBALANCE_HIST_tc,
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
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE,
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_EPIS_HIDRICS_BALANCE
   PROCEDURE del_ID_EPIS_HIDRICS_BALANCE (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_EPIS_HIDRICS_BALANCE
   PROCEDURE del_ID_EPIS_HIDRICS_BALANCE (
      id_epis_hidrics_balance_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS_BALANCE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column DT_EPIS_HBALANCE_HIST
   PROCEDURE del_DT_EPIS_HBALANCE_HIST (
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column DT_EPIS_HBALANCE_HIST
   PROCEDURE del_DT_EPIS_HBALANCE_HIST (
      dt_epis_hbalance_hist_in IN EPIS_HBALANCE_HIST.DT_EPIS_HBALANCE_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this EHBH_EHID_FK foreign key value
   PROCEDURE del_EHBH_EHID_FK (
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EHBH_EHID_FK foreign key value
   PROCEDURE del_EHBH_EHID_FK (
      id_epis_hidrics_in IN EPIS_HBALANCE_HIST.ID_EPIS_HIDRICS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EHBH_PROF_FK foreign key value
   PROCEDURE del_EHBH_PROF_FK (
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EHBH_PROF_FK foreign key value
   PROCEDURE del_EHBH_PROF_FK (
      id_prof_close_in IN EPIS_HBALANCE_HIST.ID_PROF_CLOSE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EHBH_PROF_FK2 foreign key value
   PROCEDURE del_EHBH_PROF_FK2 (
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EHBH_PROF_FK2 foreign key value
   PROCEDURE del_EHBH_PROF_FK2 (
      id_prof_last_change_in IN EPIS_HBALANCE_HIST.ID_PROF_LAST_CHANGE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EHBH_UME_FK foreign key value
   PROCEDURE del_EHBH_UME_FK (
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EHBH_UME_FK foreign key value
   PROCEDURE del_EHBH_UME_FK (
      id_unit_measure_in IN EPIS_HBALANCE_HIST.ID_UNIT_MEASURE%TYPE
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
      epis_hbalance_hist_inout IN OUT EPIS_HBALANCE_HIST%ROWTYPE
   );

   FUNCTION initrec RETURN EPIS_HBALANCE_HIST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_HBALANCE_HIST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_HBALANCE_HIST_tc;

END TS_EPIS_HBALANCE_HIST;
/
