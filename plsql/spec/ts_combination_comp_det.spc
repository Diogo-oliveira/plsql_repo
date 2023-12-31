/*-- Last Change Revision: $Rev: 2029104 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_COMBINATION_COMP_DET
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Abril 3, 2009 11:46:17
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "COMBINATION_COMP_DET"
     TYPE COMBINATION_COMP_DET_tc IS TABLE OF COMBINATION_COMP_DET%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE combination_comp_det_ntt IS TABLE OF COMBINATION_COMP_DET%ROWTYPE;
     TYPE combination_comp_det_vat IS VARRAY(100) OF COMBINATION_COMP_DET%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF COMBINATION_COMP_DET%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF COMBINATION_COMP_DET%ROWTYPE;
     TYPE vat IS VARRAY(100) OF COMBINATION_COMP_DET%ROWTYPE;

   -- Column Collection based on column "ID_COMBINATION_COMP_DET"
   TYPE ID_COMBINATION_COMP_DET_cc IS TABLE OF COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_COMPOUND_COMBINATION"
   TYPE ID_COMPOUND_COMBINATION_cc IS TABLE OF COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DRUG"
   TYPE ID_DRUG_cc IS TABLE OF COMBINATION_COMP_DET.ID_DRUG%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "QTY"
   TYPE QTY_cc IS TABLE OF COMBINATION_COMP_DET.QTY%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_UNIT_MEASURE"
   TYPE ID_UNIT_MEASURE_cc IS TABLE OF COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "VERS"
   TYPE VERS_cc IS TABLE OF COMBINATION_COMP_DET.VERS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "NOTES"
   TYPE NOTES_cc IS TABLE OF COMBINATION_COMP_DET.NOTES%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
      ,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
      ,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN COMBINATION_COMP_DET%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN COMBINATION_COMP_DET%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN COMBINATION_COMP_DET_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN COMBINATION_COMP_DET_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      ID_COMPOUND_COMBINATION_nin IN BOOLEAN := TRUE,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      ID_DRUG_nin IN BOOLEAN := TRUE,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      QTY_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      ID_COMPOUND_COMBINATION_nin IN BOOLEAN := TRUE,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      ID_DRUG_nin IN BOOLEAN := TRUE,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      QTY_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      ID_COMPOUND_COMBINATION_nin IN BOOLEAN := TRUE,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      ID_DRUG_nin IN BOOLEAN := TRUE,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      QTY_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      ID_COMPOUND_COMBINATION_nin IN BOOLEAN := TRUE,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      ID_DRUG_nin IN BOOLEAN := TRUE,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      QTY_nin IN BOOLEAN := TRUE,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      ID_UNIT_MEASURE_nin IN BOOLEAN := TRUE,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE,
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE DEFAULT NULL,
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE DEFAULT NULL,
      qty_in IN COMBINATION_COMP_DET.QTY%TYPE DEFAULT NULL,
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE DEFAULT NULL,
      notes_in IN COMBINATION_COMP_DET.NOTES%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN COMBINATION_COMP_DET%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN COMBINATION_COMP_DET%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN COMBINATION_COMP_DET_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN COMBINATION_COMP_DET_tc,
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
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_COMBINATION_COMP_DET
   PROCEDURE del_ID_COMBINATION_COMP_DET (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_COMBINATION_COMP_DET
   PROCEDURE del_ID_COMBINATION_COMP_DET (
      id_combination_comp_det_in IN COMBINATION_COMP_DET.ID_COMBINATION_COMP_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column VERS
   PROCEDURE del_VERS (
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column VERS
   PROCEDURE del_VERS (
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CCD_CC_FK foreign key value
   PROCEDURE del_CCD_CC_FK (
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CCD_CC_FK foreign key value
   PROCEDURE del_CCD_CC_FK (
      id_compound_combination_in IN COMBINATION_COMP_DET.ID_COMPOUND_COMBINATION%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CCD_MIM_FK foreign key value
   PROCEDURE del_CCD_MIM_FK (
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CCD_MIM_FK foreign key value
   PROCEDURE del_CCD_MIM_FK (
      id_drug_in IN COMBINATION_COMP_DET.ID_DRUG%TYPE,
      vers_in IN COMBINATION_COMP_DET.VERS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this CCD_UM_FK foreign key value
   PROCEDURE del_CCD_UM_FK (
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CCD_UM_FK foreign key value
   PROCEDURE del_CCD_UM_FK (
      id_unit_measure_in IN COMBINATION_COMP_DET.ID_UNIT_MEASURE%TYPE
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
      combination_comp_det_inout IN OUT COMBINATION_COMP_DET%ROWTYPE
   );

   FUNCTION initrec RETURN COMBINATION_COMP_DET%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN COMBINATION_COMP_DET_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN COMBINATION_COMP_DET_tc;

END TS_COMBINATION_COMP_DET;
/
