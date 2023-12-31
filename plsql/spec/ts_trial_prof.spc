/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE TS_TRIAL_PROF
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Janeiro 25, 2011 17:20:1
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "TRIAL_PROF"
     TYPE TRIAL_PROF_tc IS TABLE OF TRIAL_PROF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE trial_prof_ntt IS TABLE OF TRIAL_PROF%ROWTYPE;
     TYPE trial_prof_vat IS VARRAY(100) OF TRIAL_PROF%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF TRIAL_PROF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF TRIAL_PROF%ROWTYPE;
     TYPE vat IS VARRAY(100) OF TRIAL_PROF%ROWTYPE;

   -- Column Collection based on column "ID_TRIAL"
   TYPE ID_TRIAL_cc IS TABLE OF TRIAL_PROF.ID_TRIAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF TRIAL_PROF.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF TRIAL_PROF.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF TRIAL_PROF.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF TRIAL_PROF.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF TRIAL_PROF.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF TRIAL_PROF.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF TRIAL_PROF.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
      ,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
      ,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN TRIAL_PROF%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN TRIAL_PROF%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN TRIAL_PROF_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN TRIAL_PROF_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE,
      create_user_in IN TRIAL_PROF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TRIAL_PROF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TRIAL_PROF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TRIAL_PROF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TRIAL_PROF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TRIAL_PROF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN TRIAL_PROF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN TRIAL_PROF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN TRIAL_PROF_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN TRIAL_PROF_tc,
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
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE,
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_TRIAL
   PROCEDURE del_ID_TRIAL (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_TRIAL
   PROCEDURE del_ID_TRIAL (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_PROFESSIONAL
   PROCEDURE del_ID_PROFESSIONAL (
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PROFESSIONAL
   PROCEDURE del_ID_PROFESSIONAL (
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this TP_PROF_FK foreign key value
   PROCEDURE del_TP_PROF_FK (
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this TP_PROF_FK foreign key value
   PROCEDURE del_TP_PROF_FK (
      id_professional_in IN TRIAL_PROF.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this TP_T_FK foreign key value
   PROCEDURE del_TP_T_FK (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this TP_T_FK foreign key value
   PROCEDURE del_TP_T_FK (
      id_trial_in IN TRIAL_PROF.ID_TRIAL%TYPE
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
      trial_prof_inout IN OUT TRIAL_PROF%ROWTYPE
   );

   FUNCTION initrec RETURN TRIAL_PROF%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN TRIAL_PROF_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN TRIAL_PROF_tc;

END TS_TRIAL_PROF;
/
