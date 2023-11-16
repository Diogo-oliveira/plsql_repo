/*-- Last Change Revision: $Rev: 900584 $*/
/*-- Last Change by: $Author: rui.spratley $*/
/*-- Date of last change: $Date: 2011-03-01 17:44:07 +0000 (ter, 01 mar 2011) $*/


CREATE OR REPLACE PACKAGE TS_EPIS_PN_SIGNOFF
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: February 3, 2011 15:16:20
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "EPIS_PN_SIGNOFF"
     TYPE EPIS_PN_SIGNOFF_tc IS TABLE OF EPIS_PN_SIGNOFF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE epis_pn_signoff_ntt IS TABLE OF EPIS_PN_SIGNOFF%ROWTYPE;
     TYPE epis_pn_signoff_vat IS VARRAY(100) OF EPIS_PN_SIGNOFF%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF EPIS_PN_SIGNOFF%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF EPIS_PN_SIGNOFF%ROWTYPE;
     TYPE vat IS VARRAY(100) OF EPIS_PN_SIGNOFF%ROWTYPE;

   -- Column Collection based on column "ID_EPIS_PN_SIGNOFF"
   TYPE ID_EPIS_PN_SIGNOFF_cc IS TABLE OF EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_EPIS_PN"
   TYPE ID_EPIS_PN_cc IS TABLE OF EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PN_SOAP_BLOCK"
   TYPE ID_PN_SOAP_BLOCK_cc IS TABLE OF EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "PN_SIGNOFF_NOTE"
   TYPE PN_SIGNOFF_NOTE_cc IS TABLE OF EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF EPIS_PN_SIGNOFF.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF EPIS_PN_SIGNOFF.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF EPIS_PN_SIGNOFF.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROF_LAST_UPDATE"
   TYPE ID_PROF_LAST_UPDATE_cc IS TABLE OF EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "DT_LAST_UPDATE"
   TYPE DT_LAST_UPDATE_cc IS TABLE OF EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE INDEX BY BINARY_INTEGER;

   TYPE varchar2_t IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
   /*
   START Special logic for handling LOB columns....
   */
   PROCEDURE n_ins_clobs_in_chunks (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   );

   PROCEDURE n_upd_clobs_in_chunks (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN DEFAULT TRUE,
      handle_error_in IN BOOLEAN DEFAULT TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      );

   /*
   END Special logic for handling LOB columns.
   */
   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      ,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      ,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN EPIS_PN_SIGNOFF%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN EPIS_PN_SIGNOFF%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN EPIS_PN_SIGNOFF_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN EPIS_PN_SIGNOFF_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_epis_pn_signoff_out IN OUT EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      id_epis_pn_signoff_out IN OUT EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      ;

   FUNCTION ins (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      ID_EPIS_PN_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      PN_SIGNOFF_NOTE_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      ID_EPIS_PN_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      PN_SIGNOFF_NOTE_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      ID_EPIS_PN_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      PN_SIGNOFF_NOTE_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      ID_EPIS_PN_nin IN BOOLEAN := TRUE,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      ID_PN_SOAP_BLOCK_nin IN BOOLEAN := TRUE,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      PN_SIGNOFF_NOTE_nin IN BOOLEAN := TRUE,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      ID_PROF_LAST_UPDATE_nin IN BOOLEAN := TRUE,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
      DT_LAST_UPDATE_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE,
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE DEFAULT NULL,
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE DEFAULT NULL,
      pn_signoff_note_in IN EPIS_PN_SIGNOFF.PN_SIGNOFF_NOTE%TYPE DEFAULT NULL,
      create_user_in IN EPIS_PN_SIGNOFF.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN EPIS_PN_SIGNOFF.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN EPIS_PN_SIGNOFF.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN EPIS_PN_SIGNOFF.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN EPIS_PN_SIGNOFF.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN EPIS_PN_SIGNOFF.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_prof_last_update_in IN EPIS_PN_SIGNOFF.ID_PROF_LAST_UPDATE%TYPE DEFAULT NULL,
      dt_last_update_in IN EPIS_PN_SIGNOFF.DT_LAST_UPDATE%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN EPIS_PN_SIGNOFF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN EPIS_PN_SIGNOFF%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN EPIS_PN_SIGNOFF_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN EPIS_PN_SIGNOFF_tc,
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
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_EPIS_PN_SIGNOFF
   PROCEDURE del_ID_EPIS_PN_SIGNOFF (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_EPIS_PN_SIGNOFF
   PROCEDURE del_ID_EPIS_PN_SIGNOFF (
      id_epis_pn_signoff_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN_SIGNOFF%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this EPFS_EPN_FK foreign key value
   PROCEDURE del_EPFS_EPN_FK (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPFS_EPN_FK foreign key value
   PROCEDURE del_EPFS_EPN_FK (
      id_epis_pn_in IN EPIS_PN_SIGNOFF.ID_EPIS_PN%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this EPFS_PNSB_FK foreign key value
   PROCEDURE del_EPFS_PNSB_FK (
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this EPFS_PNSB_FK foreign key value
   PROCEDURE del_EPFS_PNSB_FK (
      id_pn_soap_block_in IN EPIS_PN_SIGNOFF.ID_PN_SOAP_BLOCK%TYPE
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
      epis_pn_signoff_inout IN OUT EPIS_PN_SIGNOFF%ROWTYPE
   );

   FUNCTION initrec RETURN EPIS_PN_SIGNOFF%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_PN_SIGNOFF_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN EPIS_PN_SIGNOFF_tc;

END TS_EPIS_PN_SIGNOFF;
/
