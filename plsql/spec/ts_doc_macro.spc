/*-- Last Change Revision: $Rev: 1271739 $*/
/*-- Last Change by: $Author: gustavo.serrano $*/
/*-- Date of last change: $Date: 2012-04-04 11:44:22 +0100 (qua, 04 abr 2012) $*/
CREATE OR REPLACE PACKAGE TS_DOC_MACRO
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Mar�o 30, 2012 17:0:53
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "DOC_MACRO"
     TYPE DOC_MACRO_tc IS TABLE OF DOC_MACRO%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE doc_macro_ntt IS TABLE OF DOC_MACRO%ROWTYPE;
     TYPE doc_macro_vat IS VARRAY(100) OF DOC_MACRO%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF DOC_MACRO%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF DOC_MACRO%ROWTYPE;
     TYPE vat IS VARRAY(100) OF DOC_MACRO%ROWTYPE;

   -- Column Collection based on column "ID_DOC_MACRO"
   TYPE ID_DOC_MACRO_cc IS TABLE OF DOC_MACRO.ID_DOC_MACRO%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DOC_MACRO_VERSION"
   TYPE ID_DOC_MACRO_VERSION_cc IS TABLE OF DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_CREATE"
   TYPE ID_PROF_CREATE_cc IS TABLE OF DOC_MACRO.ID_PROF_CREATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF DOC_MACRO.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_SHARE"
   TYPE FLG_SHARE_cc IS TABLE OF DOC_MACRO.FLG_SHARE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_STATUS"
   TYPE FLG_STATUS_cc IS TABLE OF DOC_MACRO.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "NOTES"
   TYPE NOTES_cc IS TABLE OF DOC_MACRO.NOTES%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_CREATION"
   TYPE DT_CREATION_cc IS TABLE OF DOC_MACRO.DT_CREATION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF DOC_MACRO.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF DOC_MACRO.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF DOC_MACRO.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF DOC_MACRO.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF DOC_MACRO.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF DOC_MACRO.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
      ,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
      ,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN DOC_MACRO%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN DOC_MACRO%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN DOC_MACRO_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN DOC_MACRO_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN DOC_MACRO.ID_DOC_MACRO%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_doc_macro_out IN OUT DOC_MACRO.ID_DOC_MACRO%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_doc_macro_out IN OUT DOC_MACRO.ID_DOC_MACRO%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         DOC_MACRO.ID_DOC_MACRO%TYPE
      ;

   FUNCTION ins (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         DOC_MACRO.ID_DOC_MACRO%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      ID_DOC_MACRO_VERSION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      FLG_SHARE_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      ID_DOC_MACRO_VERSION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      FLG_SHARE_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      ID_DOC_MACRO_VERSION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      FLG_SHARE_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      ID_DOC_MACRO_VERSION_nin IN BOOLEAN := TRUE,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      ID_PROF_CREATE_nin IN BOOLEAN := TRUE,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      FLG_SHARE_nin IN BOOLEAN := TRUE,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      FLG_STATUS_nin IN BOOLEAN := TRUE,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      NOTES_nin IN BOOLEAN := TRUE,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      DT_CREATION_nin IN BOOLEAN := TRUE,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE DEFAULT NULL,
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE DEFAULT NULL,
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE DEFAULT NULL,
      flg_share_in IN DOC_MACRO.FLG_SHARE%TYPE DEFAULT NULL,
      flg_status_in IN DOC_MACRO.FLG_STATUS%TYPE DEFAULT NULL,
      notes_in IN DOC_MACRO.NOTES%TYPE DEFAULT NULL,
      dt_creation_in IN DOC_MACRO.DT_CREATION%TYPE DEFAULT NULL,
      create_user_in IN DOC_MACRO.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN DOC_MACRO.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN DOC_MACRO.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN DOC_MACRO.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN DOC_MACRO.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN DOC_MACRO.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN DOC_MACRO%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN DOC_MACRO%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN DOC_MACRO_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN DOC_MACRO_tc,
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
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_DOC_MACRO
   PROCEDURE del_ID_DOC_MACRO (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_DOC_MACRO
   PROCEDURE del_ID_DOC_MACRO (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete for unique value of DCM_UK_IDX
   PROCEDURE del_DCM_UK_IDX (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Delete for unique value of DCM_UK_IDX
   PROCEDURE del_DCM_UK_IDX (
      id_doc_macro_in IN DOC_MACRO.ID_DOC_MACRO%TYPE,
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this DCM_DCMV_FK foreign key value
   PROCEDURE del_DCM_DCMV_FK (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this DCM_DCMV_FK foreign key value
   PROCEDURE del_DCM_DCMV_FK (
      id_doc_macro_version_in IN DOC_MACRO.ID_DOC_MACRO_VERSION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this DCM_INST_FK foreign key value
   PROCEDURE del_DCM_INST_FK (
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this DCM_INST_FK foreign key value
   PROCEDURE del_DCM_INST_FK (
      id_institution_in IN DOC_MACRO.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this DCM_PROF_FK foreign key value
   PROCEDURE del_DCM_PROF_FK (
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this DCM_PROF_FK foreign key value
   PROCEDURE del_DCM_PROF_FK (
      id_prof_create_in IN DOC_MACRO.ID_PROF_CREATE%TYPE
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
      doc_macro_inout IN OUT DOC_MACRO%ROWTYPE
   );

   FUNCTION initrec RETURN DOC_MACRO%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN DOC_MACRO_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN DOC_MACRO_tc;

END TS_DOC_MACRO;
/
