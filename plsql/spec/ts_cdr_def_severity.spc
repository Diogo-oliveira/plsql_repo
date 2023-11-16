/*-- Last Change Revision: $Rev: 1242645 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2012-02-29 10:47:31 +0000 (qua, 29 fev 2012) $*/


CREATE OR REPLACE PACKAGE TS_CDR_DEF_SEVERITY
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 28, 2012 17:44:42
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CDR_DEF_SEVERITY"
     TYPE CDR_DEF_SEVERITY_tc IS TABLE OF CDR_DEF_SEVERITY%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE cdr_def_severity_ntt IS TABLE OF CDR_DEF_SEVERITY%ROWTYPE;
     TYPE cdr_def_severity_vat IS VARRAY(100) OF CDR_DEF_SEVERITY%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CDR_DEF_SEVERITY%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CDR_DEF_SEVERITY%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CDR_DEF_SEVERITY%ROWTYPE;

   -- Column Collection based on column "ID_CDR_DEF_SEVERITY"
   TYPE ID_CDR_DEF_SEVERITY_cc IS TABLE OF CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_DEFINITION"
   TYPE ID_CDR_DEFINITION_cc IS TABLE OF CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CDR_SEVERITY"
   TYPE ID_CDR_SEVERITY_cc IS TABLE OF CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_DEFAULT"
   TYPE FLG_DEFAULT_cc IS TABLE OF CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF CDR_DEF_SEVERITY.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF CDR_DEF_SEVERITY.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF CDR_DEF_SEVERITY.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF CDR_DEF_SEVERITY.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
      ,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT 'N',
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
      ,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT 'N',
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN CDR_DEF_SEVERITY%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CDR_DEF_SEVERITY%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CDR_DEF_SEVERITY_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CDR_DEF_SEVERITY_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      ID_CDR_DEF_SEVERITY_nin IN BOOLEAN := TRUE,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      ID_CDR_DEF_SEVERITY_nin IN BOOLEAN := TRUE,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      ID_CDR_DEF_SEVERITY_nin IN BOOLEAN := TRUE,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      ID_CDR_DEF_SEVERITY_nin IN BOOLEAN := TRUE,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE,
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE DEFAULT NULL,
      flg_default_in IN CDR_DEF_SEVERITY.FLG_DEFAULT%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEF_SEVERITY.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEF_SEVERITY.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEF_SEVERITY.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEF_SEVERITY.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEF_SEVERITY.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEF_SEVERITY.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CDR_DEF_SEVERITY%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CDR_DEF_SEVERITY%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CDR_DEF_SEVERITY_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CDR_DEF_SEVERITY_tc,
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
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE,
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_CDR_DEFINITION
   PROCEDURE del_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_CDR_DEFINITION
   PROCEDURE del_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_CDR_SEVERITY
   PROCEDURE del_ID_CDR_SEVERITY (
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_CDR_SEVERITY
   PROCEDURE del_ID_CDR_SEVERITY (
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of CDRDS_UK
   PROCEDURE del_CDRDS_UK (
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of CDRDS_UK
   PROCEDURE del_CDRDS_UK (
      id_cdr_def_severity_in IN CDR_DEF_SEVERITY.ID_CDR_DEF_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRDS_CDRD_FK foreign key value
   PROCEDURE del_CDRDS_CDRD_FK (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRDS_CDRD_FK foreign key value
   PROCEDURE del_CDRDS_CDRD_FK (
      id_cdr_definition_in IN CDR_DEF_SEVERITY.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CDRDS_CDRS_FK foreign key value
   PROCEDURE del_CDRDS_CDRS_FK (
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRDS_CDRS_FK foreign key value
   PROCEDURE del_CDRDS_CDRS_FK (
      id_cdr_severity_in IN CDR_DEF_SEVERITY.ID_CDR_SEVERITY%TYPE
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
      cdr_def_severity_inout IN OUT CDR_DEF_SEVERITY%ROWTYPE
   );

   FUNCTION initrec RETURN CDR_DEF_SEVERITY%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEF_SEVERITY_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEF_SEVERITY_tc;

END TS_CDR_DEF_SEVERITY;
/