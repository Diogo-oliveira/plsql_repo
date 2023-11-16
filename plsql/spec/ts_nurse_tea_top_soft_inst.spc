/*-- Last Change Revision: $Rev: 2029261 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:50:41 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE TS_NURSE_TEA_TOP_SOFT_INST
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Maio 4, 2011 19:20:13
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "NURSE_TEA_TOP_SOFT_INST"
     TYPE NURSE_TEA_TOP_SOFT_INST_tc IS TABLE OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE nurse_tea_top_soft_inst_ntt IS TABLE OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE;
     TYPE nurse_tea_top_soft_inst_vat IS VARRAY(100) OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE;
     TYPE vat IS VARRAY(100) OF NURSE_TEA_TOP_SOFT_INST%ROWTYPE;

   -- Column Collection based on column "ID_NURSE_TEA_TOPIC"
   TYPE ID_NURSE_TEA_TOPIC_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.ID_NURSE_TEA_TOPIC%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SOFTWARE"
   TYPE ID_SOFTWARE_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.ID_SOFTWARE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_MARKET"
   TYPE ID_MARKET_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.ID_MARKET%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_AVAILABLE"
   TYPE FLG_AVAILABLE_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.FLG_AVAILABLE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_TYPE"
   TYPE FLG_TYPE_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.FLG_TYPE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DEP_CLIN_SERV"
   TYPE ID_DEP_CLIN_SERV_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.ID_DEP_CLIN_SERV%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF NURSE_TEA_TOP_SOFT_INST.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_nurse_tea_topic_in IN NURSE_TEA_TOP_SOFT_INST.ID_NURSE_TEA_TOPIC%TYPE DEFAULT NULL,
      id_software_in IN NURSE_TEA_TOP_SOFT_INST.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_institution_in IN NURSE_TEA_TOP_SOFT_INST.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_market_in IN NURSE_TEA_TOP_SOFT_INST.ID_MARKET%TYPE DEFAULT NULL,
      flg_available_in IN NURSE_TEA_TOP_SOFT_INST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_type_in IN NURSE_TEA_TOP_SOFT_INST.FLG_TYPE%TYPE DEFAULT 'P',
      id_dep_clin_serv_in IN NURSE_TEA_TOP_SOFT_INST.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_nurse_tea_topic_in IN NURSE_TEA_TOP_SOFT_INST.ID_NURSE_TEA_TOPIC%TYPE DEFAULT NULL,
      id_software_in IN NURSE_TEA_TOP_SOFT_INST.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_institution_in IN NURSE_TEA_TOP_SOFT_INST.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_market_in IN NURSE_TEA_TOP_SOFT_INST.ID_MARKET%TYPE DEFAULT NULL,
      flg_available_in IN NURSE_TEA_TOP_SOFT_INST.FLG_AVAILABLE%TYPE DEFAULT 'Y',
      flg_type_in IN NURSE_TEA_TOP_SOFT_INST.FLG_TYPE%TYPE DEFAULT 'P',
      id_dep_clin_serv_in IN NURSE_TEA_TOP_SOFT_INST.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      create_user_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN NURSE_TEA_TOP_SOFT_INST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN NURSE_TEA_TOP_SOFT_INST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN NURSE_TEA_TOP_SOFT_INST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN NURSE_TEA_TOP_SOFT_INST%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN NURSE_TEA_TOP_SOFT_INST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN NURSE_TEA_TOP_SOFT_INST_tc
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







   -- Delete all rows for this NTTSI_NTT_FK foreign key value
   PROCEDURE del_NTTSI_NTT_FK (
      id_nurse_tea_topic_in IN NURSE_TEA_TOP_SOFT_INST.ID_NURSE_TEA_TOPIC%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this NTTSI_NTT_FK foreign key value
   PROCEDURE del_NTTSI_NTT_FK (
      id_nurse_tea_topic_in IN NURSE_TEA_TOP_SOFT_INST.ID_NURSE_TEA_TOPIC%TYPE
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
      nurse_tea_top_soft_inst_inout IN OUT NURSE_TEA_TOP_SOFT_INST%ROWTYPE
   );

   FUNCTION initrec RETURN NURSE_TEA_TOP_SOFT_INST%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_TOP_SOFT_INST_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN NURSE_TEA_TOP_SOFT_INST_tc;

END TS_NURSE_TEA_TOP_SOFT_INST;
/