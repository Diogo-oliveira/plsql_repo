/*-- Last Change Revision: $Rev: 2029253 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:38 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE TS_NURSE_TEA_DET_COMPO
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 4, 2011 19:19:7
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NURSE_TEA_DET_COMPO"
     TYPE NURSE_TEA_DET_COMPO_tc IS TABLE OF NURSE_TEA_DET_COMPO%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nurse_tea_det_compo_ntt IS TABLE OF NURSE_TEA_DET_COMPO%ROWTYPE;
     TYPE nurse_tea_det_compo_vat IS VARRAY(100) OF NURSE_TEA_DET_COMPO%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NURSE_TEA_DET_COMPO%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NURSE_TEA_DET_COMPO%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NURSE_TEA_DET_COMPO%ROWTYPE;

   -- Column Collection based on column "ID_NURSE_TEA_DET_COMPO"
   TYPE ID_NURSE_TEA_DET_COMPO_cc IS TABLE OF NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_NURSE_TEA_DET"
   TYPE ID_NURSE_TEA_DET_cc IS TABLE OF NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_COMPOSITION"
   TYPE ID_COMPOSITION_cc IS TABLE OF NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NURSE_TEA_DET_COMPO.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      ,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      ,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN NURSE_TEA_DET_COMPO%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NURSE_TEA_DET_COMPO%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NURSE_TEA_DET_COMPO_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NURSE_TEA_DET_COMPO_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nurse_tea_det_compo_out IN OUT NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_nurse_tea_det_compo_out IN OUT NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      ;

   FUNCTION ins (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      ID_NURSE_TEA_DET_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      ID_NURSE_TEA_DET_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      ID_NURSE_TEA_DET_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      ID_NURSE_TEA_DET_nin IN BOOLEAN := TRUE,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      ID_COMPOSITION_nin IN BOOLEAN := TRUE,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE,
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE DEFAULT NULL,
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_DET_COMPO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_DET_COMPO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_DET_COMPO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_DET_COMPO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_DET_COMPO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_DET_COMPO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN NURSE_TEA_DET_COMPO%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN NURSE_TEA_DET_COMPO%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN NURSE_TEA_DET_COMPO_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN NURSE_TEA_DET_COMPO_tc,
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
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_NURSE_TEA_DET_COMPO
   PROCEDURE del_ID_NURSE_TEA_DET_COMPO (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_NURSE_TEA_DET_COMPO
   PROCEDURE del_ID_NURSE_TEA_DET_COMPO (
      id_nurse_tea_det_compo_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET_COMPO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this NTC_ICN_FK foreign key value
   PROCEDURE del_NTC_ICN_FK (
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NTC_ICN_FK foreign key value
   PROCEDURE del_NTC_ICN_FK (
      id_composition_in IN NURSE_TEA_DET_COMPO.ID_COMPOSITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this NTC_NTD_FK foreign key value
   PROCEDURE del_NTC_NTD_FK (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NTC_NTD_FK foreign key value
   PROCEDURE del_NTC_NTD_FK (
      id_nurse_tea_det_in IN NURSE_TEA_DET_COMPO.ID_NURSE_TEA_DET%TYPE
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
      nurse_tea_det_compo_inout IN OUT NURSE_TEA_DET_COMPO%ROWTYPE
   );

   FUNCTION initrec RETURN NURSE_TEA_DET_COMPO%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_DET_COMPO_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_DET_COMPO_tc;

END TS_NURSE_TEA_DET_COMPO;
/
