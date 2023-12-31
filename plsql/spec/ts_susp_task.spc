/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE TS_SUSP_TASK
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Junho 4, 2010 15:53:40
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "SUSP_TASK"
     TYPE SUSP_TASK_tc IS TABLE OF SUSP_TASK%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE susp_task_ntt IS TABLE OF SUSP_TASK%ROWTYPE;
     TYPE susp_task_vat IS VARRAY(100) OF SUSP_TASK%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF SUSP_TASK%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF SUSP_TASK%ROWTYPE;
     TYPE vat IS VARRAY(100) OF SUSP_TASK%ROWTYPE;

   -- Column Collection based on column "ID_SUSP_TASK"
   TYPE ID_SUSP_TASK_cc IS TABLE OF SUSP_TASK.ID_SUSP_TASK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SUSP_ACTION"
   TYPE ID_SUSP_ACTION_cc IS TABLE OF SUSP_TASK.ID_SUSP_ACTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF SUSP_TASK.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF SUSP_TASK.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF SUSP_TASK.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF SUSP_TASK.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF SUSP_TASK.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF SUSP_TASK.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF SUSP_TASK.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
      ,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
      ,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN SUSP_TASK%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN SUSP_TASK%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN SUSP_TASK_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN SUSP_TASK_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN SUSP_TASK.ID_SUSP_TASK%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_susp_task_out IN OUT SUSP_TASK.ID_SUSP_TASK%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_susp_task_out IN OUT SUSP_TASK.ID_SUSP_TASK%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         SUSP_TASK.ID_SUSP_TASK%TYPE
      ;

   FUNCTION ins (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         SUSP_TASK.ID_SUSP_TASK%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      ID_SUSP_ACTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      ID_SUSP_ACTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      ID_SUSP_ACTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      ID_SUSP_ACTION_nin IN BOOLEAN := TRUE,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE,
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE DEFAULT NULL,
      flg_status_in IN SUSP_TASK.FLG_STATUS%TYPE DEFAULT NULL,
      create_user_in IN SUSP_TASK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SUSP_TASK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SUSP_TASK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SUSP_TASK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SUSP_TASK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SUSP_TASK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN SUSP_TASK%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN SUSP_TASK%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN SUSP_TASK_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN SUSP_TASK_tc,
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
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_SUSP_TASK
   PROCEDURE del_ID_SUSP_TASK (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SUSP_TASK
   PROCEDURE del_ID_SUSP_TASK (
      id_susp_task_in IN SUSP_TASK.ID_SUSP_TASK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this WSKT_WSN_FK foreign key value
   PROCEDURE del_WSKT_WSN_FK (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this WSKT_WSN_FK foreign key value
   PROCEDURE del_WSKT_WSN_FK (
      id_susp_action_in IN SUSP_TASK.ID_SUSP_ACTION%TYPE
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
      susp_task_inout IN OUT SUSP_TASK%ROWTYPE
   );

   FUNCTION initrec RETURN SUSP_TASK%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN SUSP_TASK_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN SUSP_TASK_tc;

END TS_SUSP_TASK;
/
