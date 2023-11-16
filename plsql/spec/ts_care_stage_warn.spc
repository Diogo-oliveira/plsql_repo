/*-- Last Change Revision: $Rev: 2029100 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_CARE_STAGE_WARN
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Mar�o 7, 2009 15:37:58
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CARE_STAGE_WARN"
     TYPE CARE_STAGE_WARN_tc IS TABLE OF CARE_STAGE_WARN%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE care_stage_warn_ntt IS TABLE OF CARE_STAGE_WARN%ROWTYPE;
     TYPE care_stage_warn_vat IS VARRAY(100) OF CARE_STAGE_WARN%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CARE_STAGE_WARN%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CARE_STAGE_WARN%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CARE_STAGE_WARN%ROWTYPE;

   -- Column Collection based on column "FLG_STAGE"
   TYPE FLG_STAGE_cc IS TABLE OF CARE_STAGE_WARN.FLG_STAGE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF CARE_STAGE_WARN.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SOFTWARE"
   TYPE ID_SOFTWARE_cc IS TABLE OF CARE_STAGE_WARN.ID_SOFTWARE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "TIME_TO_WARN"
   TYPE TIME_TO_WARN_cc IS TABLE OF CARE_STAGE_WARN.TIME_TO_WARN%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
      ,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
      ,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN CARE_STAGE_WARN%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CARE_STAGE_WARN%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CARE_STAGE_WARN_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CARE_STAGE_WARN_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
      TIME_TO_WARN_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
      TIME_TO_WARN_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
      TIME_TO_WARN_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
      TIME_TO_WARN_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE,
      time_to_warn_in IN CARE_STAGE_WARN.TIME_TO_WARN%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CARE_STAGE_WARN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CARE_STAGE_WARN%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CARE_STAGE_WARN_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CARE_STAGE_WARN_tc,
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
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE,
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE,
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column FLG_STAGE
   PROCEDURE del_FLG_STAGE (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column FLG_STAGE
   PROCEDURE del_FLG_STAGE (
      flg_stage_in IN CARE_STAGE_WARN.FLG_STAGE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_INSTITUTION
   PROCEDURE del_ID_INSTITUTION (
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_INSTITUTION
   PROCEDURE del_ID_INSTITUTION (
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_SOFTWARE
   PROCEDURE del_ID_SOFTWARE (
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SOFTWARE
   PROCEDURE del_ID_SOFTWARE (
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CSW_INST_FK foreign key value
   PROCEDURE del_CSW_INST_FK (
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CSW_INST_FK foreign key value
   PROCEDURE del_CSW_INST_FK (
      id_institution_in IN CARE_STAGE_WARN.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CSW_SW_FK foreign key value
   PROCEDURE del_CSW_SW_FK (
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CSW_SW_FK foreign key value
   PROCEDURE del_CSW_SW_FK (
      id_software_in IN CARE_STAGE_WARN.ID_SOFTWARE%TYPE
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
      care_stage_warn_inout IN OUT CARE_STAGE_WARN%ROWTYPE
   );

   FUNCTION initrec RETURN CARE_STAGE_WARN%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CARE_STAGE_WARN_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CARE_STAGE_WARN_tc;

END TS_CARE_STAGE_WARN;
/