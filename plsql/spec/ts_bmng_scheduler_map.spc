/*-- Last Change Revision: $Rev: 1779838 $*/
/*-- Last Change by: $Author: vanessa.barsottelli $*/
/*-- Date of last change: $Date: 2017-04-20 15:32:24 +0100 (qui, 20 abr 2017) $*/
CREATE OR REPLACE PACKAGE TS_BMNG_SCHEDULER_MAP
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: October 31, 2016 15:0:57
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "BMNG_SCHEDULER_MAP"
     TYPE BMNG_SCHEDULER_MAP_tc IS TABLE OF BMNG_SCHEDULER_MAP%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE bmng_scheduler_map_ntt IS TABLE OF BMNG_SCHEDULER_MAP%ROWTYPE;
     TYPE bmng_scheduler_map_vat IS VARRAY(100) OF BMNG_SCHEDULER_MAP%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF BMNG_SCHEDULER_MAP%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF BMNG_SCHEDULER_MAP%ROWTYPE;
     TYPE vat IS VARRAY(100) OF BMNG_SCHEDULER_MAP%ROWTYPE;

   -- Column Collection based on column "ID_RESOURCE_PFH"
   TYPE ID_RESOURCE_PFH_cc IS TABLE OF BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_RESOURCE_EXT"
   TYPE ID_RESOURCE_EXT_cc IS TABLE OF BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATED"
   TYPE DT_CREATED_cc IS TABLE OF BMNG_SCHEDULER_MAP.DT_CREATED%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF BMNG_SCHEDULER_MAP.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
      ,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT CURRENT_TIMESTAMP,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
      ,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT CURRENT_TIMESTAMP,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   PROCEDURE ins (
      rec_in IN BMNG_SCHEDULER_MAP%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN BMNG_SCHEDULER_MAP%ROWTYPE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN BMNG_SCHEDULER_MAP_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN BMNG_SCHEDULER_MAP_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      DT_CREATED_nin IN BOOLEAN := TRUE,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE,
      dt_created_in IN BMNG_SCHEDULER_MAP.DT_CREATED%TYPE DEFAULT NULL,
      create_user_in IN BMNG_SCHEDULER_MAP.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN BMNG_SCHEDULER_MAP.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN BMNG_SCHEDULER_MAP.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN BMNG_SCHEDULER_MAP.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN BMNG_SCHEDULER_MAP.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN BMNG_SCHEDULER_MAP.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN BMNG_SCHEDULER_MAP%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN BMNG_SCHEDULER_MAP%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN BMNG_SCHEDULER_MAP_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN BMNG_SCHEDULER_MAP_tc,
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
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE,
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_RESOURCE_PFH
   PROCEDURE del_ID_RESOURCE_PFH (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_RESOURCE_PFH
   PROCEDURE del_ID_RESOURCE_PFH (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );


   -- Delete all rows for primary key column ID_RESOURCE_EXT
   PROCEDURE del_ID_RESOURCE_EXT (
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_RESOURCE_EXT
   PROCEDURE del_ID_RESOURCE_EXT (
      id_resource_ext_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_EXT%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this BSM_BMNG_FK foreign key value
   PROCEDURE del_BSM_BMNG_FK (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this BSM_BMNG_FK foreign key value
   PROCEDURE del_BSM_BMNG_FK (
      id_resource_pfh_in IN BMNG_SCHEDULER_MAP.ID_RESOURCE_PFH%TYPE
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
      bmng_scheduler_map_inout IN OUT BMNG_SCHEDULER_MAP%ROWTYPE
   );

   FUNCTION initrec RETURN BMNG_SCHEDULER_MAP%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN BMNG_SCHEDULER_MAP_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN BMNG_SCHEDULER_MAP_tc;

END TS_BMNG_SCHEDULER_MAP;
/
