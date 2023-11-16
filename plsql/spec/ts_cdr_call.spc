/*-- Last Change Revision: $Rev: 1242645 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2012-02-29 10:47:31 +0000 (qua, 29 fev 2012) $*/


CREATE OR REPLACE PACKAGE TS_CDR_CALL
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 28, 2012 17:44:13
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CDR_CALL"
     TYPE CDR_CALL_tc IS TABLE OF CDR_CALL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE cdr_call_ntt IS TABLE OF CDR_CALL%ROWTYPE;
     TYPE cdr_call_vat IS VARRAY(100) OF CDR_CALL%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CDR_CALL%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CDR_CALL%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CDR_CALL%ROWTYPE;

   -- Column Collection based on column "ID_CDR_CALL"
   TYPE ID_CDR_CALL_cc IS TABLE OF CDR_CALL.ID_CDR_CALL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CALL"
   TYPE ID_PROF_CALL_cc IS TABLE OF CDR_CALL.ID_PROF_CALL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CALL"
   TYPE DT_CALL_cc IS TABLE OF CDR_CALL.DT_CALL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPISODE"
   TYPE ID_EPISODE_cc IS TABLE OF CDR_CALL.ID_EPISODE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PATIENT"
   TYPE ID_PATIENT_cc IS TABLE OF CDR_CALL.ID_PATIENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF CDR_CALL.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF CDR_CALL.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF CDR_CALL.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF CDR_CALL.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF CDR_CALL.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF CDR_CALL.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_CALL_PARENT"
   TYPE ID_CDR_CALL_PARENT_cc IS TABLE OF CDR_CALL.ID_CDR_CALL_PARENT%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
      ,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
      ,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN CDR_CALL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CDR_CALL%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CDR_CALL_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CDR_CALL_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN CDR_CALL.ID_CDR_CALL%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      id_cdr_call_out IN OUT CDR_CALL.ID_CDR_CALL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      id_cdr_call_out IN OUT CDR_CALL.ID_CDR_CALL%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         CDR_CALL.ID_CDR_CALL%TYPE
      ;

   FUNCTION ins (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         CDR_CALL.ID_CDR_CALL%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      ID_PROF_CALL_nin IN BOOLEAN := TRUE,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      DT_CALL_nin IN BOOLEAN := TRUE,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      ID_CDR_CALL_PARENT_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      ID_PROF_CALL_nin IN BOOLEAN := TRUE,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      DT_CALL_nin IN BOOLEAN := TRUE,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      ID_CDR_CALL_PARENT_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      ID_PROF_CALL_nin IN BOOLEAN := TRUE,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      DT_CALL_nin IN BOOLEAN := TRUE,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      ID_CDR_CALL_PARENT_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      ID_PROF_CALL_nin IN BOOLEAN := TRUE,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      DT_CALL_nin IN BOOLEAN := TRUE,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      ID_EPISODE_nin IN BOOLEAN := TRUE,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
      ID_CDR_CALL_PARENT_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE,
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE DEFAULT NULL,
      dt_call_in IN CDR_CALL.DT_CALL%TYPE DEFAULT NULL,
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE DEFAULT NULL,
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE DEFAULT NULL,
      create_user_in IN CDR_CALL.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_CALL.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_CALL.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_CALL.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_CALL.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_CALL.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CDR_CALL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CDR_CALL%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CDR_CALL_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CDR_CALL_tc,
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
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_CDR_CALL
   PROCEDURE del_ID_CDR_CALL (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_CDR_CALL
   PROCEDURE del_ID_CDR_CALL (
      id_cdr_call_in IN CDR_CALL.ID_CDR_CALL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CDRL_CDRL_FK foreign key value
   PROCEDURE del_CDRL_CDRL_FK (
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRL_CDRL_FK foreign key value
   PROCEDURE del_CDRL_CDRL_FK (
      id_cdr_call_parent_in IN CDR_CALL.ID_CDR_CALL_PARENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRL_EPIS_FK foreign key value
   PROCEDURE del_CDRL_EPIS_FK (
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRL_EPIS_FK foreign key value
   PROCEDURE del_CDRL_EPIS_FK (
      id_episode_in IN CDR_CALL.ID_EPISODE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRL_PAT_FK foreign key value
   PROCEDURE del_CDRL_PAT_FK (
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRL_PAT_FK foreign key value
   PROCEDURE del_CDRL_PAT_FK (
      id_patient_in IN CDR_CALL.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRL_PROF_FK foreign key value
   PROCEDURE del_CDRL_PROF_FK (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRL_PROF_FK foreign key value
   PROCEDURE del_CDRL_PROF_FK (
      id_prof_call_in IN CDR_CALL.ID_PROF_CALL%TYPE
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
      cdr_call_inout IN OUT CDR_CALL%ROWTYPE
   );

   FUNCTION initrec RETURN CDR_CALL%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_CALL_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_CALL_tc;

END TS_CDR_CALL;
/
