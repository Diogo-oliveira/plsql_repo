/*-- Last Change Revision: $Rev: 1589482 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-05-13 14:54:56 +0100 (ter, 13 mai 2014) $*/
CREATE OR REPLACE PACKAGE TS_CDR_DEFINITION_HIST
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: April 16, 2014 15:37:56
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CDR_DEFINITION_HIST"
     TYPE CDR_DEFINITION_HIST_tc IS TABLE OF CDR_DEFINITION_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE cdr_definition_hist_ntt IS TABLE OF CDR_DEFINITION_HIST%ROWTYPE;
     TYPE cdr_definition_hist_vat IS VARRAY(100) OF CDR_DEFINITION_HIST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CDR_DEFINITION_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CDR_DEFINITION_HIST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CDR_DEFINITION_HIST%ROWTYPE;

   -- Column Collection based on column "ID_CDR_DEFINITION"
   TYPE ID_CDR_DEFINITION_cc IS TABLE OF CDR_DEFINITION_HIST.ID_CDR_DEFINITION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF CDR_DEFINITION_HIST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF CDR_DEFINITION_HIST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF CDR_DEFINITION_HIST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF CDR_DEFINITION_HIST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF CDR_DEFINITION_HIST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF CDR_DEFINITION_HIST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_LINKS_NEW"
   TYPE ID_LINKS_NEW_cc IS TABLE OF CDR_DEFINITION_HIST.ID_LINKS_NEW%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_LINKS_OLD"
   TYPE ID_LINKS_OLD_cc IS TABLE OF CDR_DEFINITION_HIST.ID_LINKS_OLD%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "STATUS_NEW"
   TYPE STATUS_NEW_cc IS TABLE OF CDR_DEFINITION_HIST.STATUS_NEW%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "STATUS_OLD"
   TYPE STATUS_OLD_cc IS TABLE OF CDR_DEFINITION_HIST.STATUS_OLD%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEFINITION_HIST.ID_CDR_DEFINITION%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_links_new_in IN CDR_DEFINITION_HIST.ID_LINKS_NEW%TYPE DEFAULT NULL,
      id_links_old_in IN CDR_DEFINITION_HIST.ID_LINKS_OLD%TYPE DEFAULT NULL,
      status_new_in IN CDR_DEFINITION_HIST.STATUS_NEW%TYPE DEFAULT NULL,
      status_old_in IN CDR_DEFINITION_HIST.STATUS_OLD%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_cdr_definition_in IN CDR_DEFINITION_HIST.ID_CDR_DEFINITION%TYPE DEFAULT NULL,
      create_user_in IN CDR_DEFINITION_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN CDR_DEFINITION_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN CDR_DEFINITION_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN CDR_DEFINITION_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN CDR_DEFINITION_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN CDR_DEFINITION_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_links_new_in IN CDR_DEFINITION_HIST.ID_LINKS_NEW%TYPE DEFAULT NULL,
      id_links_old_in IN CDR_DEFINITION_HIST.ID_LINKS_OLD%TYPE DEFAULT NULL,
      status_new_in IN CDR_DEFINITION_HIST.STATUS_NEW%TYPE DEFAULT NULL,
      status_old_in IN CDR_DEFINITION_HIST.STATUS_OLD%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN CDR_DEFINITION_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CDR_DEFINITION_HIST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CDR_DEFINITION_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CDR_DEFINITION_HIST_tc
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







   -- Delete all rows for this CDRDH_ID_CDR_DEFINITION foreign key value
   PROCEDURE del_CDRDH_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEFINITION_HIST.ID_CDR_DEFINITION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CDRDH_ID_CDR_DEFINITION foreign key value
   PROCEDURE del_CDRDH_ID_CDR_DEFINITION (
      id_cdr_definition_in IN CDR_DEFINITION_HIST.ID_CDR_DEFINITION%TYPE
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
      cdr_definition_hist_inout IN OUT CDR_DEFINITION_HIST%ROWTYPE
   );

   FUNCTION initrec RETURN CDR_DEFINITION_HIST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEFINITION_HIST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CDR_DEFINITION_HIST_tc;

END TS_CDR_DEFINITION_HIST;
/
