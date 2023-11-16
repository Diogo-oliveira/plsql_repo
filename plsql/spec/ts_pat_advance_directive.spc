/*-- Last Change Revision: $Rev: 2029273 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_PAT_ADVANCE_DIRECTIVE
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: February 23, 2009 15:43:52
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PAT_ADVANCE_DIRECTIVE"
     TYPE PAT_ADVANCE_DIRECTIVE_tc IS TABLE OF PAT_ADVANCE_DIRECTIVE%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE pat_advance_directive_ntt IS TABLE OF PAT_ADVANCE_DIRECTIVE%ROWTYPE;
     TYPE pat_advance_directive_vat IS VARRAY(100) OF PAT_ADVANCE_DIRECTIVE%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PAT_ADVANCE_DIRECTIVE%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PAT_ADVANCE_DIRECTIVE%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PAT_ADVANCE_DIRECTIVE%ROWTYPE;

   -- Column Collection based on column "ID_PAT_ADVANCE_DIRECTIVE"
   TYPE ID_PAT_ADVANCE_DIRECTIVE_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PATIENT"
   TYPE ID_PATIENT_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPIS_DOCUMENTATION"
   TYPE ID_EPIS_DOCUMENTATION_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_HAS_ADV_DIRECTIVE"
   TYPE FLG_HAS_ADV_DIRECTIVE_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_CANCEL_REASON"
   TYPE ID_CANCEL_REASON_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CANCEL"
   TYPE ID_PROF_CANCEL_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "NOTES_CANCEL"
   TYPE NOTES_CANCEL_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CANCEL"
   TYPE DT_CANCEL_cc IS TABLE OF PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      ,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      ,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PAT_ADVANCE_DIRECTIVE%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PAT_ADVANCE_DIRECTIVE%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PAT_ADVANCE_DIRECTIVE_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PAT_ADVANCE_DIRECTIVE_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      id_pat_advance_directive_out IN OUT PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      id_pat_advance_directive_out IN OUT PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      ;

   FUNCTION ins (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      ID_EPIS_DOCUMENTATION_nin IN BOOLEAN := TRUE,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      FLG_HAS_ADV_DIRECTIVE_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      ID_CANCEL_REASON_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      NOTES_CANCEL_nin IN BOOLEAN := TRUE,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      DT_CANCEL_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      ID_EPIS_DOCUMENTATION_nin IN BOOLEAN := TRUE,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      FLG_HAS_ADV_DIRECTIVE_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      ID_CANCEL_REASON_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      NOTES_CANCEL_nin IN BOOLEAN := TRUE,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      DT_CANCEL_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      ID_EPIS_DOCUMENTATION_nin IN BOOLEAN := TRUE,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      FLG_HAS_ADV_DIRECTIVE_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      ID_CANCEL_REASON_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      NOTES_CANCEL_nin IN BOOLEAN := TRUE,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      DT_CANCEL_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      ID_PATIENT_nin IN BOOLEAN := TRUE,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      ID_EPIS_DOCUMENTATION_nin IN BOOLEAN := TRUE,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      FLG_HAS_ADV_DIRECTIVE_nin IN BOOLEAN := TRUE,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      ID_CANCEL_REASON_nin IN BOOLEAN := TRUE,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      ID_PROF_CANCEL_nin IN BOOLEAN := TRUE,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      NOTES_CANCEL_nin IN BOOLEAN := TRUE,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
      DT_CANCEL_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE,
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE DEFAULT NULL,
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE DEFAULT NULL,
      flg_has_adv_directive_in IN PAT_ADVANCE_DIRECTIVE.FLG_HAS_ADV_DIRECTIVE%TYPE DEFAULT NULL,
      flg_status_in IN PAT_ADVANCE_DIRECTIVE.FLG_STATUS%TYPE DEFAULT NULL,
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE DEFAULT NULL,
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE DEFAULT NULL,
      notes_cancel_in IN PAT_ADVANCE_DIRECTIVE.NOTES_CANCEL%TYPE DEFAULT NULL,
      dt_cancel_in IN PAT_ADVANCE_DIRECTIVE.DT_CANCEL%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PAT_ADVANCE_DIRECTIVE%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PAT_ADVANCE_DIRECTIVE%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PAT_ADVANCE_DIRECTIVE_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PAT_ADVANCE_DIRECTIVE_tc,
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
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PAT_ADVANCE_DIRECTIVE
   PROCEDURE del_ID_PAT_ADVANCE_DIRECTIVE (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PAT_ADVANCE_DIRECTIVE
   PROCEDURE del_ID_PAT_ADVANCE_DIRECTIVE (
      id_pat_advance_directive_in IN PAT_ADVANCE_DIRECTIVE.ID_PAT_ADVANCE_DIRECTIVE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this PATADVDIR_CRE_FK foreign key value
   PROCEDURE del_PATADVDIR_CRE_FK (
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PATADVDIR_CRE_FK foreign key value
   PROCEDURE del_PATADVDIR_CRE_FK (
      id_cancel_reason_in IN PAT_ADVANCE_DIRECTIVE.ID_CANCEL_REASON%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PATADVDIR_EPISD_FK foreign key value
   PROCEDURE del_PATADVDIR_EPISD_FK (
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PATADVDIR_EPISD_FK foreign key value
   PROCEDURE del_PATADVDIR_EPISD_FK (
      id_epis_documentation_in IN PAT_ADVANCE_DIRECTIVE.ID_EPIS_DOCUMENTATION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PATADVDIR_PAT_FK foreign key value
   PROCEDURE del_PATADVDIR_PAT_FK (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PATADVDIR_PAT_FK foreign key value
   PROCEDURE del_PATADVDIR_PAT_FK (
      id_patient_in IN PAT_ADVANCE_DIRECTIVE.ID_PATIENT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PATADVDIR_PROFC_FK foreign key value
   PROCEDURE del_PATADVDIR_PROFC_FK (
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PATADVDIR_PROFC_FK foreign key value
   PROCEDURE del_PATADVDIR_PROFC_FK (
      id_prof_cancel_in IN PAT_ADVANCE_DIRECTIVE.ID_PROF_CANCEL%TYPE
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
      pat_advance_directive_inout IN OUT PAT_ADVANCE_DIRECTIVE%ROWTYPE
   );

   FUNCTION initrec RETURN PAT_ADVANCE_DIRECTIVE%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PAT_ADVANCE_DIRECTIVE_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PAT_ADVANCE_DIRECTIVE_tc;

END TS_PAT_ADVANCE_DIRECTIVE;
/
