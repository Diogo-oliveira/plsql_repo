/*-- Last Change Revision: $Rev: 480440 $*/
/*-- Last Change by: $Author: joao.almeida $*/
/*-- Date of last change: $Date: 2010-04-20 12:27:05 +0100 (ter, 20 abr 2010) $*/

CREATE OR REPLACE PACKAGE ts_task_goal_det IS

    -- Author  : JOAO.ALMEIDA
    -- Created : 13-04-2010 15:18:03
    -- Purpose : 

  -- Collection of %ROWTYPE records based on "TASK_GOAL_DET"
     TYPE TASK_GOAL_DET_tc IS TABLE OF TASK_GOAL_DET%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE task_goal_det_ntt IS TABLE OF TASK_GOAL_DET%ROWTYPE;
     TYPE task_goal_det_vat IS VARRAY(100) OF TASK_GOAL_DET%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF TASK_GOAL_DET%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF TASK_GOAL_DET%ROWTYPE;
     TYPE vat IS VARRAY(100) OF TASK_GOAL_DET%ROWTYPE;

   -- Column Collection based on column "ID_TASK_GOAL_DET"
   TYPE ID_TASK_GOAL_DET_cc IS TABLE OF TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_TASK_GOAL"
   TYPE ID_TASK_GOAL_cc IS TABLE OF TASK_GOAL_DET.ID_TASK_GOAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DESC_TASK_GOAL"
   TYPE DESC_TASK_GOAL_cc IS TABLE OF TASK_GOAL_DET.DESC_TASK_GOAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF TASK_GOAL_DET.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF TASK_GOAL_DET.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF TASK_GOAL_DET.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF TASK_GOAL_DET.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF TASK_GOAL_DET.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
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
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      ,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      ,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN TASK_GOAL_DET%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN TASK_GOAL_DET%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN TASK_GOAL_DET_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN TASK_GOAL_DET_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_out IN OUT TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_out IN OUT TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      ;

   FUNCTION ins (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE,
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN TASK_GOAL_DET%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN TASK_GOAL_DET%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN TASK_GOAL_DET_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN TASK_GOAL_DET_tc,
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
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_TASK_GOAL_DET
   PROCEDURE del_ID_TASK_GOAL_DET (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_TASK_GOAL_DET
   PROCEDURE del_ID_TASK_GOAL_DET (
      id_task_goal_det_in IN TASK_GOAL_DET.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this TGLD_TGL_FK foreign key value
   PROCEDURE del_TGLD_TGL_FK (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this TGLD_TGL_FK foreign key value
   PROCEDURE del_TGLD_TGL_FK (
      id_task_goal_in IN TASK_GOAL_DET.ID_TASK_GOAL%TYPE
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
      task_goal_det_inout IN OUT TASK_GOAL_DET%ROWTYPE
   );

   FUNCTION initrec RETURN TASK_GOAL_DET%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN TASK_GOAL_DET_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN TASK_GOAL_DET_tc;
END ts_task_goal_det;
/
