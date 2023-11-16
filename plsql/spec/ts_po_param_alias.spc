/*-- Last Change Revision: $Rev: 1686632 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2015-03-02 11:36:04 +0000 (seg, 02 mar 2015) $*/

CREATE OR REPLACE PACKAGE TS_PO_PARAM_ALIAS
/*
| Generated by or retrieved from QCGU - DO NOT MODIFY!
| QCGU - "Get it right, do it fast" - www.ToadWorld.com
| QCGU Universal ID: {1BD37A66-EA60-4927-9A64-F6DD89237236}
| Created On: Fevereiro 9, 2015 9:48:7
| Created By: ALERT
*/
IS

  -- Collection of %ROWTYPE records based on "PO_PARAM_ALIAS"
     TYPE PO_PARAM_ALIAS_tc IS TABLE OF PO_PARAM_ALIAS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE po_param_alias_ntt IS TABLE OF PO_PARAM_ALIAS%ROWTYPE;
     TYPE po_param_alias_vat IS VARRAY(100) OF PO_PARAM_ALIAS%ROWTYPE;

  -- Same type structure, with a static name.
     TYPE aat IS TABLE OF PO_PARAM_ALIAS%ROWTYPE INDEX BY BINARY_INTEGER;
     TYPE ntt IS TABLE OF PO_PARAM_ALIAS%ROWTYPE;
     TYPE vat IS VARRAY(100) OF PO_PARAM_ALIAS%ROWTYPE;

   -- Column Collection based on column "ID_PO_PARAM_ALIAS"
   TYPE ID_PO_PARAM_ALIAS_cc IS TABLE OF PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CODE_PO_PARAM_ALIAS"
   TYPE CODE_PO_PARAM_ALIAS_cc IS TABLE OF PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PO_PARAM"
   TYPE ID_PO_PARAM_cc IS TABLE OF PO_PARAM_ALIAS.ID_PO_PARAM%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INST_OWNER"
   TYPE ID_INST_OWNER_cc IS TABLE OF PO_PARAM_ALIAS.ID_INST_OWNER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_INSTITUTION"
   TYPE ID_INSTITUTION_cc IS TABLE OF PO_PARAM_ALIAS.ID_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_SOFTWARE"
   TYPE ID_SOFTWARE_cc IS TABLE OF PO_PARAM_ALIAS.ID_SOFTWARE%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_DEP_CLIN_SERV"
   TYPE ID_DEP_CLIN_SERV_cc IS TABLE OF PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "ID_PROFESSIONAL"
   TYPE ID_PROFESSIONAL_cc IS TABLE OF PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_USER"
   TYPE CREATE_USER_cc IS TABLE OF PO_PARAM_ALIAS.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_TIME"
   TYPE CREATE_TIME_cc IS TABLE OF PO_PARAM_ALIAS.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "CREATE_INSTITUTION"
   TYPE CREATE_INSTITUTION_cc IS TABLE OF PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_USER"
   TYPE UPDATE_USER_cc IS TABLE OF PO_PARAM_ALIAS.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_TIME"
   TYPE UPDATE_TIME_cc IS TABLE OF PO_PARAM_ALIAS.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
   -- Column Collection based on column "UPDATE_INSTITUTION"
   TYPE UPDATE_INSTITUTION_cc IS TABLE OF PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;

   -- Insert one row, providing primary key if present
   PROCEDURE ins (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      ,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      ,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );


   -- Insert a row based on a record.
   -- Specify whether or not a primary key value should be generated.
   PROCEDURE ins (
      rec_in IN PO_PARAM_ALIAS%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rec_in IN PO_PARAM_ALIAS%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Insert a collection of rows using FORALL; all primary key values
   -- must have already been generated, or are handled in triggers.
   PROCEDURE ins (
      rows_in IN PO_PARAM_ALIAS_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   );

   PROCEDURE ins (
      rows_in IN PO_PARAM_ALIAS_tc
     ,handle_error_in IN BOOLEAN := TRUE
   );

   -- Return next primary key value using the named sequence.
     FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE;

   -- Insert one row, generating hidden primary key using a sequence
   PROCEDURE ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row, returning primary key generated by sequence
   PROCEDURE ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_po_param_alias_out IN OUT PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   PROCEDURE ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_po_param_alias_out IN OUT PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      );

   -- Insert one row with function, return generated primary key
   FUNCTION ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
      RETURN
         PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      ;

   FUNCTION ins (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      -- Pass false if you want errors to propagate out unhandled
     ,handle_error_in IN BOOLEAN := TRUE
      )
      RETURN
         PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
      ;

   -- Update any/all columns by primary key. If you pass NULL, then
   -- the current column value is set to itself. If you need a more
   -- selected UPDATE then use one of the onecol procedures below.

  PROCEDURE upd (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      CODE_PO_PARAM_ALIAS_nin IN BOOLEAN := TRUE,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


       PROCEDURE upd (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      CODE_PO_PARAM_ALIAS_nin IN BOOLEAN := TRUE,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      );



      PROCEDURE upd (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      CODE_PO_PARAM_ALIAS_nin IN BOOLEAN := TRUE,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );


      PROCEDURE upd (
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      CODE_PO_PARAM_ALIAS_nin IN BOOLEAN := TRUE,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      ID_PO_PARAM_nin IN BOOLEAN := TRUE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      ID_INST_OWNER_nin IN BOOLEAN := TRUE,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      ID_INSTITUTION_nin IN BOOLEAN := TRUE,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      ID_SOFTWARE_nin IN BOOLEAN := TRUE,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      ID_DEP_CLIN_SERV_nin IN BOOLEAN := TRUE,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      ID_PROFESSIONAL_nin IN BOOLEAN := TRUE,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2,
     handle_error_in IN BOOLEAN := TRUE
      );



   PROCEDURE upd_ins (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

      PROCEDURE upd_ins (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE,
      code_po_param_alias_in IN PO_PARAM_ALIAS.CODE_PO_PARAM_ALIAS%TYPE DEFAULT NULL,
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE DEFAULT NULL,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE DEFAULT NULL,
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE DEFAULT NULL,
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE DEFAULT NULL,
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE DEFAULT NULL,
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE DEFAULT NULL,
      create_user_in IN PO_PARAM_ALIAS.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN PO_PARAM_ALIAS.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN PO_PARAM_ALIAS.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN PO_PARAM_ALIAS.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN PO_PARAM_ALIAS.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN PO_PARAM_ALIAS.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      );

   PROCEDURE upd (
      rec_in IN PO_PARAM_ALIAS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      rec_in IN PO_PARAM_ALIAS%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_ALIAS_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      );

      PROCEDURE upd (
      col_in IN PO_PARAM_ALIAS_tc,
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
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

-- Delete one row by primary key
   PROCEDURE del (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );


   -- Delete all rows for primary key column ID_PO_PARAM_ALIAS
   PROCEDURE del_ID_PO_PARAM_ALIAS (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     );

     -- Delete all rows for primary key column ID_PO_PARAM_ALIAS
   PROCEDURE del_ID_PO_PARAM_ALIAS (
      id_po_param_alias_in IN PO_PARAM_ALIAS.ID_PO_PARAM_ALIAS%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     );

   -- Delete all rows for this POPA_DCS_FK foreign key value
   PROCEDURE del_POPA_DCS_FK (
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPA_DCS_FK foreign key value
   PROCEDURE del_POPA_DCS_FK (
      id_dep_clin_serv_in IN PO_PARAM_ALIAS.ID_DEP_CLIN_SERV%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPA_INST_FK foreign key value
   PROCEDURE del_POPA_INST_FK (
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPA_INST_FK foreign key value
   PROCEDURE del_POPA_INST_FK (
      id_institution_in IN PO_PARAM_ALIAS.ID_INSTITUTION%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPA_POP_FK foreign key value
   PROCEDURE del_POPA_POP_FK (
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPA_POP_FK foreign key value
   PROCEDURE del_POPA_POP_FK (
      id_po_param_in IN PO_PARAM_ALIAS.ID_PO_PARAM%TYPE,
      id_inst_owner_in IN PO_PARAM_ALIAS.ID_INST_OWNER%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPA_PROF_FK foreign key value
   PROCEDURE del_POPA_PROF_FK (
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPA_PROF_FK foreign key value
   PROCEDURE del_POPA_PROF_FK (
      id_professional_in IN PO_PARAM_ALIAS.ID_PROFESSIONAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      );

   -- Delete all rows for this POPA_SOFT_FK foreign key value
   PROCEDURE del_POPA_SOFT_FK (
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      );

      -- Delete all rows for this POPA_SOFT_FK foreign key value
   PROCEDURE del_POPA_SOFT_FK (
      id_software_in IN PO_PARAM_ALIAS.ID_SOFTWARE%TYPE
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
      po_param_alias_inout IN OUT PO_PARAM_ALIAS%ROWTYPE
   );

   FUNCTION initrec RETURN PO_PARAM_ALIAS%ROWTYPE;



   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_ALIAS_tc;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN PO_PARAM_ALIAS_tc;

END TS_PO_PARAM_ALIAS;
/