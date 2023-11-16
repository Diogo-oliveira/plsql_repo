/*-- Last Change Revision: $Rev: 2029099 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE TS_CARE_STAGE_SET_PERMISSIONS
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Mar�o 25, 2009 23:16:50
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "CARE_STAGE_SET_PERMISSIONS"
     TYPE CARE_STAGE_SET_PERMISSIONS_tc IS TABLE OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE care_stage_set_permissions_ntt IS TABLE OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE;
     TYPE care_stage_set_permissions_vat IS VARRAY(100) OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE;
     TYPE vat IS VARRAY(100) OF CARE_STAGE_SET_PERMISSIONS%ROWTYPE;

   -- Column Collection based on column "ID_PROFILE_TEMPLATE"
   TYPE ID_PROFILE_TEMPLATE_cc IS TABLE OF CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DOMAIN_VAL"
   TYPE DOMAIN_VAL_cc IS TABLE OF CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_SET"
   TYPE FLG_SET_cc IS TABLE OF CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
      ,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
      ,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN CARE_STAGE_SET_PERMISSIONS%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN CARE_STAGE_SET_PERMISSIONS%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN CARE_STAGE_SET_PERMISSIONS_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN CARE_STAGE_SET_PERMISSIONS_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
      FLG_SET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
      FLG_SET_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
      FLG_SET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
      FLG_SET_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE,
      flg_set_in IN CARE_STAGE_SET_PERMISSIONS.FLG_SET%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN CARE_STAGE_SET_PERMISSIONS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN CARE_STAGE_SET_PERMISSIONS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN CARE_STAGE_SET_PERMISSIONS_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN CARE_STAGE_SET_PERMISSIONS_tc,
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
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE,
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PROFILE_TEMPLATE
   PROCEDURE del_ID_PROFILE_TEMPLATE (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PROFILE_TEMPLATE
   PROCEDURE del_ID_PROFILE_TEMPLATE (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column DOMAIN_VAL
   PROCEDURE del_DOMAIN_VAL (
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column DOMAIN_VAL
   PROCEDURE del_DOMAIN_VAL (
      domain_val_in IN CARE_STAGE_SET_PERMISSIONS.DOMAIN_VAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this CSSP_PT_FK foreign key value
   PROCEDURE del_CSSP_PT_FK (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this CSSP_PT_FK foreign key value
   PROCEDURE del_CSSP_PT_FK (
      id_profile_template_in IN CARE_STAGE_SET_PERMISSIONS.ID_PROFILE_TEMPLATE%TYPE
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
      care_stage_set_perm_inout IN OUT CARE_STAGE_SET_PERMISSIONS%ROWTYPE
   );

   FUNCTION initrec RETURN CARE_STAGE_SET_PERMISSIONS%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN CARE_STAGE_SET_PERMISSIONS_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN CARE_STAGE_SET_PERMISSIONS_tc;

END TS_CARE_STAGE_SET_PERMISSIONS;
/