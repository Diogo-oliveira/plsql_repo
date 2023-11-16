/*-- Last Change Revision: $Rev: 2029373 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:18 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE TS_SCH_API_MAP_IDS
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: January 14, 2013 16:8:5
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "SCH_API_MAP_IDS"
     TYPE SCH_API_MAP_IDS_tc IS TABLE OF SCH_API_MAP_IDS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE sch_api_map_ids_ntt IS TABLE OF SCH_API_MAP_IDS%ROWTYPE;
     TYPE sch_api_map_ids_vat IS VARRAY(100) OF SCH_API_MAP_IDS%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF SCH_API_MAP_IDS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF SCH_API_MAP_IDS%ROWTYPE;
     TYPE vat IS VARRAY(100) OF SCH_API_MAP_IDS%ROWTYPE;

   -- Column Collection based on column "ID_SCHEDULE_PFH"
   TYPE ID_SCHEDULE_PFH_cc IS TABLE OF SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SCHEDULE_EXT"
   TYPE ID_SCHEDULE_EXT_cc IS TABLE OF SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF SCH_API_MAP_IDS.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF SCH_API_MAP_IDS.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF SCH_API_MAP_IDS.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF SCH_API_MAP_IDS.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SCHEDULE_PROCEDURE"
   TYPE ID_SCHEDULE_PROCEDURE_cc IS TABLE OF SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATED"
   TYPE DT_CREATED_cc IS TABLE OF SCH_API_MAP_IDS.DT_CREATED%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
      ,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT current_timestamp
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
      ,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT current_timestamp
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN SCH_API_MAP_IDS%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN SCH_API_MAP_IDS%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN SCH_API_MAP_IDS_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN SCH_API_MAP_IDS_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      ID_SCHEDULE_PROCEDURE_nin IN BOOLEAN := TRUE,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      ID_SCHEDULE_PROCEDURE_nin IN BOOLEAN := TRUE,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      ID_SCHEDULE_PROCEDURE_nin IN BOOLEAN := TRUE,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      ID_SCHEDULE_PROCEDURE_nin IN BOOLEAN := TRUE,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE,
      create_user_in IN SCH_API_MAP_IDS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN SCH_API_MAP_IDS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN SCH_API_MAP_IDS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN SCH_API_MAP_IDS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN SCH_API_MAP_IDS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN SCH_API_MAP_IDS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_schedule_procedure_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PROCEDURE%TYPE DEFAULT NULL,
      dt_created_in IN SCH_API_MAP_IDS.DT_CREATED%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN SCH_API_MAP_IDS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN SCH_API_MAP_IDS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN SCH_API_MAP_IDS_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN SCH_API_MAP_IDS_tc,
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
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE,
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_SCHEDULE_PFH
   PROCEDURE del_ID_SCHEDULE_PFH (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SCHEDULE_PFH
   PROCEDURE del_ID_SCHEDULE_PFH (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_SCHEDULE_EXT
   PROCEDURE del_ID_SCHEDULE_EXT (
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_SCHEDULE_EXT
   PROCEDURE del_ID_SCHEDULE_EXT (
      id_schedule_ext_in IN SCH_API_MAP_IDS.ID_SCHEDULE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this SAMI_ID_SCH_PFH_FK foreign key value
   PROCEDURE del_SAMI_ID_SCH_PFH_FK (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this SAMI_ID_SCH_PFH_FK foreign key value
   PROCEDURE del_SAMI_ID_SCH_PFH_FK (
      id_schedule_pfh_in IN SCH_API_MAP_IDS.ID_SCHEDULE_PFH%TYPE
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
      sch_api_map_ids_inout IN OUT SCH_API_MAP_IDS%ROWTYPE
   );

   FUNCTION initrec RETURN SCH_API_MAP_IDS%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN SCH_API_MAP_IDS_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN SCH_API_MAP_IDS_tc;

END TS_SCH_API_MAP_IDS;
/
