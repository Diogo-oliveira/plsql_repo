/*-- Last Change Revision: $Rev: 2029322 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:01 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE TS_PROF_DEP_CLIN_SERV
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Outubro 22, 2008 16:55:48
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PROF_DEP_CLIN_SERV"
     TYPE PROF_DEP_CLIN_SERV_tc IS TABLE OF PROF_DEP_CLIN_SERV%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE prof_dep_clin_serv_ntt IS TABLE OF PROF_DEP_CLIN_SERV%ROWTYPE;
     TYPE prof_dep_clin_serv_vat IS VARRAY(100) OF PROF_DEP_CLIN_SERV%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PROF_DEP_CLIN_SERV%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PROF_DEP_CLIN_SERV%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PROF_DEP_CLIN_SERV%ROWTYPE;

   -- Column Collection based on column "ID_PROF_DEP_CLIN_SERV"
   TYPE ID_PROF_DEP_CLIN_SERV_cc IS TABLE OF PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DEP_CLIN_SERV"
   TYPE ID_DEP_CLIN_SERV_cc IS TABLE OF PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_DEFAULT"
   TYPE FLG_DEFAULT_cc IS TABLE OF PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION"
   TYPE DT_CREATION_cc IS TABLE OF PROF_DEP_CLIN_SERV.DT_CREATION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      ,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      ,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PROF_DEP_CLIN_SERV%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PROF_DEP_CLIN_SERV%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PROF_DEP_CLIN_SERV_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PROF_DEP_CLIN_SERV_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      id_prof_dep_clin_serv_out IN OUT PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      id_prof_dep_clin_serv_out IN OUT PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      ;

   FUNCTION ins (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT 'N'
,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      FLG_DEFAULT_nin IN BOOLEAN := TRUE,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE,
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      flg_status_in IN PROF_DEP_CLIN_SERV.FLG_STATUS%TYPE DEFAULT NULL,
      flg_default_in IN PROF_DEP_CLIN_SERV.FLG_DEFAULT%TYPE DEFAULT NULL,
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE DEFAULT NULL,
      dt_creation_in IN PROF_DEP_CLIN_SERV.DT_CREATION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PROF_DEP_CLIN_SERV%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PROF_DEP_CLIN_SERV%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PROF_DEP_CLIN_SERV_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PROF_DEP_CLIN_SERV_tc,
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
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PROF_DEP_CLIN_SERV
   PROCEDURE del_ID_PROF_DEP_CLIN_SERV (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PROF_DEP_CLIN_SERV
   PROCEDURE del_ID_PROF_DEP_CLIN_SERV (
      id_prof_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_PROF_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of PDCS_PRF_DCS_I
   PROCEDURE del_PDCS_PRF_DCS_I (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of PDCS_PRF_DCS_I
   PROCEDURE del_PDCS_PRF_DCS_I (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE,
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PCST_DCS_FK foreign key value
   PROCEDURE del_PCST_DCS_FK (
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PCST_DCS_FK foreign key value
   PROCEDURE del_PCST_DCS_FK (
      id_dep_clin_serv_in IN PROF_DEP_CLIN_SERV.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PCST_INST_FK foreign key value
   PROCEDURE del_PCST_INST_FK (
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PCST_INST_FK foreign key value
   PROCEDURE del_PCST_INST_FK (
      id_institution_in IN PROF_DEP_CLIN_SERV.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this PCST_PROF_FK foreign key value
   PROCEDURE del_PCST_PROF_FK (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this PCST_PROF_FK foreign key value
   PROCEDURE del_PCST_PROF_FK (
      id_professional_in IN PROF_DEP_CLIN_SERV.ID_PROFESSIONAL%TYPE
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
      prof_dep_clin_serv_inout IN OUT PROF_DEP_CLIN_SERV%ROWTYPE
   );

   FUNCTION initrec RETURN PROF_DEP_CLIN_SERV%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PROF_DEP_CLIN_SERV_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PROF_DEP_CLIN_SERV_tc;

END TS_PROF_DEP_CLIN_SERV;
/
/
