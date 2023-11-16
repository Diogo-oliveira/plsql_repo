/*-- Last Change Revision: $Rev: 1686632 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2015-03-02 11:36:04 +0000 (seg, 02 mar 2015) $*/

CREATE OR REPLACE PACKAGE TS_PO_PARAM_RANK
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 9, 2015 9:48:20
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PO_PARAM_RANK"
     TYPE PO_PARAM_RANK_tc IS TABLE OF PO_PARAM_RANK%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE po_param_rank_ntt IS TABLE OF PO_PARAM_RANK%ROWTYPE;
     TYPE po_param_rank_vat IS VARRAY(100) OF PO_PARAM_RANK%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PO_PARAM_RANK%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PO_PARAM_RANK%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PO_PARAM_RANK%ROWTYPE;

   -- Column Collection based on column "ID_PO_PARAM_RANK"
   TYPE ID_PO_PARAM_RANK_cc IS TABLE OF PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PO_PARAM"
   TYPE ID_PO_PARAM_cc IS TABLE OF PO_PARAM_RANK.ID_PO_PARAM%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INST_OWNER"
   TYPE ID_INST_OWNER_cc IS TABLE OF PO_PARAM_RANK.ID_INST_OWNER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "RANK"
   TYPE RANK_cc IS TABLE OF PO_PARAM_RANK.RANK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF PO_PARAM_RANK.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SOFTWARE"
   TYPE ID_SOFTWARE_cc IS TABLE OF PO_PARAM_RANK.ID_SOFTWARE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "FLG_AVAILABLE"
   TYPE FLG_AVAILABLE_cc IS TABLE OF PO_PARAM_RANK.FLG_AVAILABLE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PO_PARAM_RANK.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PO_PARAM_RANK.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PO_PARAM_RANK.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PO_PARAM_RANK.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PO_PARAM_RANK.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      ,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      ,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PO_PARAM_RANK%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PO_PARAM_RANK%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PO_PARAM_RANK_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PO_PARAM_RANK_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_po_param_rank_out IN OUT PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_po_param_rank_out IN OUT PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      ;

   FUNCTION ins (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      RANK_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      FLG_AVAILABLE_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE,
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE DEFAULT NULL,
      rank_in IN PO_PARAM_RANK.RANK%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE DEFAULT NULL,
      flg_available_in IN PO_PARAM_RANK.FLG_AVAILABLE%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_RANK.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_RANK.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_RANK.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_RANK.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_RANK.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_RANK.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PO_PARAM_RANK%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PO_PARAM_RANK%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_RANK_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_RANK_tc,
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
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PO_PARAM_RANK
   PROCEDURE del_ID_PO_PARAM_RANK (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PO_PARAM_RANK
   PROCEDURE del_ID_PO_PARAM_RANK (
      id_po_param_rank_in IN PO_PARAM_RANK.ID_PO_PARAM_RANK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this POPRK_INST_FK foreign key value
   PROCEDURE del_POPRK_INST_FK (
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPRK_INST_FK foreign key value
   PROCEDURE del_POPRK_INST_FK (
      id_institution_in IN PO_PARAM_RANK.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPRK_POP_FK foreign key value
   PROCEDURE del_POPRK_POP_FK (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPRK_POP_FK foreign key value
   PROCEDURE del_POPRK_POP_FK (
      id_po_param_in IN PO_PARAM_RANK.ID_PO_PARAM%TYPE,
      id_inst_owner_in IN PO_PARAM_RANK.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPRK_SOFT_FK foreign key value
   PROCEDURE del_POPRK_SOFT_FK (
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPRK_SOFT_FK foreign key value
   PROCEDURE del_POPRK_SOFT_FK (
      id_software_in IN PO_PARAM_RANK.ID_SOFTWARE%TYPE
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
      po_param_rank_inout IN OUT PO_PARAM_RANK%ROWTYPE
   );

   FUNCTION initrec RETURN PO_PARAM_RANK%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_RANK_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_RANK_tc;

END TS_PO_PARAM_RANK;
/