/*-- Last Change Revision: $Rev: 1496857 $*/
/*-- Last Change by: $Author: jorge.silva $*/
/*-- Date of last change: $Date: 2013-08-26 12:09:08 +0100 (seg, 26 ago 2013) $*/
CREATE OR REPLACE PACKAGE TS_PO_PARAM_REG_MC
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Agosto 16, 2013 16:12:19
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PO_PARAM_REG_MC"
     TYPE PO_PARAM_REG_MC_tc IS TABLE OF PO_PARAM_REG_MC%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE po_param_reg_mc_ntt IS TABLE OF PO_PARAM_REG_MC%ROWTYPE;
     TYPE po_param_reg_mc_vat IS VARRAY(100) OF PO_PARAM_REG_MC%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PO_PARAM_REG_MC%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PO_PARAM_REG_MC%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PO_PARAM_REG_MC%ROWTYPE;

   -- Column Collection based on column "ID_PO_PARAM_REG"
   TYPE ID_PO_PARAM_REG_cc IS TABLE OF PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PO_PARAM_MC"
   TYPE ID_PO_PARAM_MC_cc IS TABLE OF PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PO_PARAM_REG_MC.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PO_PARAM_REG_MC.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PO_PARAM_REG_MC.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PO_PARAM_REG_MC.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
      ,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
      ,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN PO_PARAM_REG_MC%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PO_PARAM_REG_MC%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PO_PARAM_REG_MC_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PO_PARAM_REG_MC_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE,
      create_user_in IN PO_PARAM_REG_MC.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_REG_MC.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_REG_MC.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_REG_MC.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_REG_MC.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_REG_MC.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PO_PARAM_REG_MC%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PO_PARAM_REG_MC%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_REG_MC_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_REG_MC_tc,
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
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE,
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PO_PARAM_REG
   PROCEDURE del_ID_PO_PARAM_REG (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PO_PARAM_REG
   PROCEDURE del_ID_PO_PARAM_REG (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_PO_PARAM_MC
   PROCEDURE del_ID_PO_PARAM_MC (
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PO_PARAM_MC
   PROCEDURE del_ID_PO_PARAM_MC (
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this POPRMC_POPMC_FK foreign key value
   PROCEDURE del_POPRMC_POPMC_FK (
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPRMC_POPMC_FK foreign key value
   PROCEDURE del_POPRMC_POPMC_FK (
      id_po_param_mc_in IN PO_PARAM_REG_MC.ID_PO_PARAM_MC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPRMC_POPR_FK foreign key value
   PROCEDURE del_POPRMC_POPR_FK (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPRMC_POPR_FK foreign key value
   PROCEDURE del_POPRMC_POPR_FK (
      id_po_param_reg_in IN PO_PARAM_REG_MC.ID_PO_PARAM_REG%TYPE
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
      po_param_reg_mc_inout IN OUT PO_PARAM_REG_MC%ROWTYPE
   );

   FUNCTION initrec RETURN PO_PARAM_REG_MC%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_REG_MC_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_REG_MC_tc;

END TS_PO_PARAM_REG_MC;
/
