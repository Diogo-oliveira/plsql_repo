/*-- Last Change Revision: $Rev: 480440 $*/
/*-- Last Change by: $Author: joao.almeida $*/
/*-- Date of last change: $Date: 2010-04-20 12:27:05 +0100 (ter, 20 abr 2010) $*/

CREATE OR REPLACE PACKAGE BODY ts_task_goal_det_hist IS
	/* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    e_null_column_value EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_null_column_value, -1400);
   --
   e_existing_fky_reference EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_existing_fky_reference, -2266);
   --
   e_check_constraint_failure EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_check_constraint_failure, -2290);
   --
   e_no_parent_key EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_no_parent_key, -2291);
   --
   e_child_record_found EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_child_record_found, -2292);
   --
   e_forall_error EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_forall_error, -24381);
   --
   -- Defined for backward compatibilty.
   e_integ_constraint_failure EXCEPTION;
   PRAGMA EXCEPTION_INIT (e_integ_constraint_failure, -2291);

    -- Private utilities
   PROCEDURE get_constraint_info (
      owner_out OUT ALL_CONSTRAINTS.OWNER%TYPE
     ,name_out OUT ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE)
   IS
      l_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
      dotloc PLS_INTEGER;
      leftloc PLS_INTEGER;
   BEGIN
      dotloc  := INSTR (l_errm,'.');
      leftloc := INSTR (l_errm,'(');
      owner_out := SUBSTR (l_errm, leftloc+1, dotloc-leftloc-1);
      name_out  := SUBSTR (l_errm, dotloc+1, INSTR (l_errm,')')-dotloc-1);
   END get_constraint_info;
   -- Public programs

   PROCEDURE ins (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
      ,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
     ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN

     INSERT INTO TASK_GOAL_DET_HIST (
         ID_TASK_GOAL_DET_HIST,
         ID_TASK_GOAL_DET,
         ID_TASK_GOAL,
         DESC_TASK_GOAL,
         CREATE_USER,
         CREATE_TIME,
         CREATE_INSTITUTION,
         UPDATE_USER,
         UPDATE_TIME,
         UPDATE_INSTITUTION
         )
      VALUES (
         id_task_goal_det_hist_in,
         id_task_goal_det_in,
         id_task_goal_in,
         desc_task_goal_in,
         create_user_in,
         create_time_in,
         create_institution_in,
         update_user_in,
         update_time_in,
         update_institution_in
         ) RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'TASK_GOAL_DET_HIST');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           IF l_name = 'TGLDH_TGLD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           IF l_name = 'TGLDH_TGL_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL'
               , value_in => id_task_goal_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END ins;

   PROCEDURE ins (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
      ,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN

     ins (
      id_task_goal_det_hist_in => id_task_goal_det_hist_in
      ,
      id_task_goal_det_in => id_task_goal_det_in,
      id_task_goal_in => id_task_goal_in,
      desc_task_goal_in => desc_task_goal_in,
      create_user_in => create_user_in,
      create_time_in => create_time_in,
      create_institution_in => create_institution_in,
      update_user_in => update_user_in,
      update_time_in => update_time_in,
      update_institution_in => update_institution_in
     ,handle_error_in => handle_error_in
      ,rows_out => rows_out
      );
   END ins;

   /*
   START Special logic for handling LOB columns....
   */

   PROCEDURE n_ins_clobs_in_chunks (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
   ) IS
        l_DESC_TASK_GOAL clob;
      i                PLS_INTEGER;
      current_column varchar2(30) := '';
   BEGIN
      /* Be aware, PLSQL limitations on temporary clobs prevent multiple CLOB
         variables from pointing to the same temporary CLOB (it creates copies).
         Otherwise, the code could have been written a bit more compactly. */

      FOR i IN clob_columns_in.FIRST .. clob_columns_in.LAST
      LOOP
         /* Even when all clobs are null, DOA must send 1 row so skip it. */
         IF clob_columns_in (i) IS NOT NULL
         THEN
            IF current_column <> clob_columns_in (i) OR current_column IS NULL
            THEN
               current_column := LOWER (clob_columns_in (i));

               CASE current_column
                  WHEN 'desc_task_goal_in'
                  THEN
                     IF l_DESC_TASK_GOAL IS NULL
                     THEN
                       DBMS_LOB.createtemporary (
                         l_DESC_TASK_GOAL, TRUE, DBMS_LOB.CALL);
                     END IF;
               END CASE;
            END IF;

            CASE current_column
              WHEN 'desc_task_goal_in'
              THEN
                  DBMS_LOB.writeappend (l_DESC_TASK_GOAL
                                      , LENGTH (clob_pieces_in (i))
                                      , clob_pieces_in (i)
                                       );
            END CASE;
         END IF;
      END LOOP;

      ins (
         id_task_goal_det_hist_in => id_task_goal_det_hist_in,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => l_DESC_TASK_GOAL,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         handle_error_in => handle_error_in
         );

   END n_ins_clobs_in_chunks;

   PROCEDURE n_upd_clobs_in_chunks (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN := TRUE,
      handle_error_in IN BOOLEAN := TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      )
   IS
       l_DESC_TASK_GOAL clob;
      i                PLS_INTEGER;
      current_column varchar2(30) := '';
      l_rows PLS_INTEGER;
   BEGIN

      /* Be aware, PLSQL limitations on temporary clobs prevent multiple CLOB
         variables from pointing to the same temporary CLOB (it creates copies).
         Otherwise, the code could have been written a bit more compactly. */

      FOR i IN clob_columns_in.FIRST .. clob_columns_in.LAST
      LOOP
         /* Even when all clobs are null, DOA must send 1 row so skip it. */
         IF clob_columns_in (i) IS NOT NULL
         THEN
            IF current_column <> clob_columns_in (i) OR current_column IS NULL
            THEN
               current_column := LOWER (clob_columns_in (i));

               CASE current_column
                  WHEN 'desc_task_goal_in'
                  THEN
                    IF l_DESC_TASK_GOAL IS NULL
                    THEN
                      DBMS_LOB.createtemporary (
                         l_DESC_TASK_GOAL, TRUE, DBMS_LOB.CALL);
                    END IF;
               END CASE;
            END IF;

            CASE current_column
              WHEN 'desc_task_goal_in'
              THEN
                  DBMS_LOB.writeappend (l_DESC_TASK_GOAL
                                      , LENGTH (clob_pieces_in (i))
                                      , clob_pieces_in (i)
                                       );
            END CASE;
         END IF;
      END LOOP;

      upd (
         id_task_goal_det_hist_in => id_task_goal_det_hist_in,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => l_DESC_TASK_GOAL,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         handle_error_in => handle_error_in
         );
   END n_upd_clobs_in_chunks;

   PROCEDURE n_upd_ins_clobs_in_chunks (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      ignore_if_null_in IN BOOLEAN DEFAULT TRUE,
      handle_error_in IN BOOLEAN DEFAULT TRUE,
      clob_columns_in IN varchar2_t,
      clob_pieces_in IN  varchar2_t
      )
   IS
   BEGIN
      n_upd_clobs_in_chunks (
         id_task_goal_det_hist_in => id_task_goal_det_hist_in,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in,
         clob_columns_in => clob_columns_in ,
         clob_pieces_in => clob_pieces_in ,
         ignore_if_null_in => ignore_if_null_in,
         handle_error_in => handle_error_in
       );

      IF SQL%ROWCOUNT = 0
      THEN
         n_ins_clobs_in_chunks (
            id_task_goal_det_hist_in => id_task_goal_det_hist_in,
            id_task_goal_det_in => id_task_goal_det_in,
            id_task_goal_in => id_task_goal_in,
            create_user_in => create_user_in,
            create_time_in => create_time_in,
            create_institution_in => create_institution_in,
            update_user_in => update_user_in,
            update_time_in => update_time_in,
            update_institution_in => update_institution_in,
            clob_columns_in => clob_columns_in ,
            clob_pieces_in => clob_pieces_in ,
            handle_error_in => handle_error_in
         );
      END IF;
   END n_upd_ins_clobs_in_chunks;

   /*
   END Special logic for handling LOB columns.
   */

   PROCEDURE ins (
      rec_in IN TASK_GOAL_DET_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
      l_rec TASK_GOAL_DET_HIST%ROWTYPE := rec_in;
   BEGIN
      IF gen_pky_in THEN
         l_rec.ID_TASK_GOAL_DET_HIST := next_key (sequence_in);
      END IF;
      ins (
         id_task_goal_det_hist_in => l_rec.ID_TASK_GOAL_DET_HIST
         ,
         id_task_goal_det_in => l_rec.ID_TASK_GOAL_DET,
         id_task_goal_in => l_rec.ID_TASK_GOAL,
         desc_task_goal_in => l_rec.DESC_TASK_GOAL,
         create_user_in => l_rec.CREATE_USER,
         create_time_in => l_rec.CREATE_TIME,
         create_institution_in => l_rec.CREATE_INSTITUTION,
         update_user_in => l_rec.UPDATE_USER,
         update_time_in => l_rec.UPDATE_TIME,
         update_institution_in => l_rec.UPDATE_INSTITUTION
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;

   PROCEDURE ins (
      rec_in IN TASK_GOAL_DET_HIST%ROWTYPE
     ,gen_pky_in IN BOOLEAN DEFAULT FALSE
     ,sequence_in IN VARCHAR2 := NULL
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
      rows_out TABLE_VARCHAR;
   BEGIN

  ins (
      rec_in => rec_in
     ,gen_pky_in => gen_pky_in
     ,sequence_in => sequence_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
   );

   END ins;

   FUNCTION next_key (sequence_in IN VARCHAR2 := NULL) RETURN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE

   IS
     retval TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE;

   BEGIN
      IF sequence_in IS NULL
      THEN
         SELECT seq_TASK_GOAL_DET_HIST.NEXTVAL INTO retval FROM dual;
      ELSE
         EXECUTE IMMEDIATE
            'SELECT ' || sequence_in || '.NEXTVAL FROM dual'
            INTO retval;
      END IF;
      RETURN retval;
   EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'SEQUENCE-GENERATION-FAILURE'
           ,name1_in => 'SEQUENCE'
           ,value1_in => NVL (sequence_in, 'seq_TASK_GOAL_DET_HIST')
           );
   END next_key;

   PROCEDURE ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_hist_out IN OUT TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
   IS
        l_pky TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE := next_key;
   BEGIN
      ins (
         id_task_goal_det_hist_in => l_pky,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      id_task_goal_det_hist_out := l_pky;
   END ins;

   PROCEDURE ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      id_task_goal_det_hist_out IN OUT TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
      ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      ins (
      id_task_goal_det_in => id_task_goal_det_in,
      id_task_goal_in => id_task_goal_in,
      desc_task_goal_in => desc_task_goal_in,
      create_user_in => create_user_in,
      create_time_in => create_time_in,
      create_institution_in => create_institution_in,
      update_user_in => update_user_in,
      update_time_in => update_time_in,
      update_institution_in => update_institution_in,
      id_task_goal_det_hist_out => id_task_goal_det_hist_out
      ,handle_error_in => handle_error_in
      , rows_out => rows_out
   );
   END ins;

   FUNCTION ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
      RETURN
         TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
   IS
        l_pky TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE := next_key;
   BEGIN
      ins (
         id_task_goal_det_hist_in => l_pky,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      RETURN l_pky;
   END ins;

   FUNCTION ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
   )
      RETURN
         TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
   IS
        l_pky TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE := next_key;
    rows_out TABLE_VARCHAR;
   BEGIN
      ins (
         id_task_goal_det_hist_in => l_pky,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
      RETURN l_pky;
   END ins;

      PROCEDURE ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
      , rows_out OUT TABLE_VARCHAR
   )
   IS
        l_pky TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE := next_key;
   BEGIN
      ins (
         id_task_goal_det_hist_in => l_pky,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;


     PROCEDURE ins (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL
      ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
        l_pky TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE := next_key;
      rows_out TABLE_VARCHAR;
   BEGIN
      ins (
         id_task_goal_det_hist_in => l_pky,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
         );
   END ins;

    PROCEDURE ins (
      rows_in IN TASK_GOAL_DET_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      IF rows_in.COUNT = 0
      THEN
         NULL;
      ELSE
         FORALL indx IN rows_in.FIRST .. rows_in.LAST
            SAVE EXCEPTIONS
            INSERT INTO TASK_GOAL_DET_HIST VALUES rows_in (indx) RETURNING ROWID BULK COLLECT INTO rows_out;
      END IF;
   EXCEPTION
     WHEN e_forall_error
     THEN
        -- In Oracle9i and above, SAVE EXCEPTIONS will direct control
        -- here if any error occurs. We can then save all the error
        -- information out to the error instance.
       IF NOT handle_error_in THEN RAISE;
       ELSE
          <<bulk_handler>>
          DECLARE
             l_err_instance_id NUMBER;
          BEGIN
             -- For each error, write to the log.
             FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
             LOOP
                pk_alert_exceptions.register_error (
                    error_name_in => 'FORALL-INSERT-FAILURE'
                   ,err_instance_id_out => l_err_instance_id
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'BINDING_ROW_' || indx
                  ,value_in => SQL%BULK_EXCEPTIONS (indx).ERROR_INDEX
                  ,validate_in => FALSE
                );
                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ERROR_AT_ROW_' || indx
                  ,value_in => SQL%BULK_EXCEPTIONS (indx).ERROR_CODE
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_TASK_GOAL_DET_HIST _' || indx
                  ,value_in => rows_in(indx).ID_TASK_GOAL_DET_HIST
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_TASK_GOAL_DET _' || indx
                  ,value_in => rows_in(indx).ID_TASK_GOAL_DET
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'ID_TASK_GOAL _' || indx
                  ,value_in => rows_in(indx).ID_TASK_GOAL
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_USER _' || indx
                  ,value_in => rows_in(indx).CREATE_USER
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_TIME _' || indx
                  ,value_in => rows_in(indx).CREATE_TIME
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'CREATE_INSTITUTION _' || indx
                  ,value_in => rows_in(indx).CREATE_INSTITUTION
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_USER _' || indx
                  ,value_in => rows_in(indx).UPDATE_USER
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_TIME _' || indx
                  ,value_in => rows_in(indx).UPDATE_TIME
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.add_context (
                   err_instance_id_in => l_err_instance_id
                  ,NAME_IN => 'UPDATE_INSTITUTION _' || indx
                  ,value_in => rows_in(indx).UPDATE_INSTITUTION
                  ,validate_in => FALSE
                );

                pk_alert_exceptions.raise_error_instance( err_instance_id_in => l_err_instance_id );
             END LOOP;
          END bulk_handler;
        END IF;
     WHEN OTHERS
     THEN
       IF NOT handle_error_in THEN RAISE;
       ELSE
       pk_alert_exceptions.raise_error(
          error_name_in => 'FORALL-INSERT-FAILURE'
          ,name1_in => 'TABLE_NAME'
          ,value1_in => 'TASK_GOAL_DET_HIST'
          ,name2_in => 'ROW_COUNT'
          ,value2_in => rows_in.COUNT
           );
       END IF;
   END ins;

    PROCEDURE ins (
      rows_in IN TASK_GOAL_DET_HIST_tc
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
      rows_out TABLE_VARCHAR;
   BEGIN
      ins (
      rows_in => rows_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
   );
   END ins;


PROCEDURE upd (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   l_rows_out TABLE_VARCHAR;
   l_ID_TASK_GOAL_DET_n NUMBER(1);
   l_ID_TASK_GOAL_n NUMBER(1);
   l_DESC_TASK_GOAL_n NUMBER(1);
   l_CREATE_USER_n NUMBER(1);
   l_CREATE_TIME_n NUMBER(1);
   l_CREATE_INSTITUTION_n NUMBER(1);
   l_UPDATE_USER_n NUMBER(1);
   l_UPDATE_TIME_n NUMBER(1);
   l_UPDATE_INSTITUTION_n NUMBER(1);
   BEGIN

   l_ID_TASK_GOAL_DET_n := sys.diutil.bool_to_int(ID_TASK_GOAL_DET_nin);
   l_ID_TASK_GOAL_n := sys.diutil.bool_to_int(ID_TASK_GOAL_nin);
   l_DESC_TASK_GOAL_n := sys.diutil.bool_to_int(DESC_TASK_GOAL_nin);
   l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
   l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
   l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
   l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
   l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
   l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);


         UPDATE TASK_GOAL_DET_HIST SET
     ID_TASK_GOAL_DET = decode (l_ID_TASK_GOAL_DET_n,0,id_task_goal_det_in, NVL (id_task_goal_det_in, ID_TASK_GOAL_DET)),
     ID_TASK_GOAL = decode (l_ID_TASK_GOAL_n,0,id_task_goal_in, NVL (id_task_goal_in, ID_TASK_GOAL)),
     DESC_TASK_GOAL = decode (l_DESC_TASK_GOAL_n,0,desc_task_goal_in, NVL (desc_task_goal_in, DESC_TASK_GOAL)),
     CREATE_USER = decode (l_CREATE_USER_n,0,create_user_in, NVL (create_user_in, CREATE_USER)),
     CREATE_TIME = decode (l_CREATE_TIME_n,0,create_time_in, NVL (create_time_in, CREATE_TIME)),
     CREATE_INSTITUTION = decode (l_CREATE_INSTITUTION_n,0,create_institution_in, NVL (create_institution_in, CREATE_INSTITUTION)),
     UPDATE_USER = decode (l_UPDATE_USER_n,0,update_user_in, NVL (update_user_in, UPDATE_USER)),
     UPDATE_TIME = decode (l_UPDATE_TIME_n,0,update_time_in, NVL (update_time_in, UPDATE_TIME)),
     UPDATE_INSTITUTION = decode (l_UPDATE_INSTITUTION_n,0,update_institution_in, NVL (update_institution_in, UPDATE_INSTITUTION))
          WHERE
             ID_TASK_GOAL_DET_HIST = id_task_goal_det_hist_in
         RETURNING ROWID BULK COLLECT INTO l_rows_out;


if(rows_out is null)
then
rows_out := table_varchar();
end if;

rows_out :=  rows_out MULTISET UNION DISTINCT l_rows_out;

   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'TASK_GOAL_DET_HIST');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           IF l_name = 'TGLDH_TGLD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           IF l_name = 'TGLDH_TGL_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL'
               , value_in => id_task_goal_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END upd;


   PROCEDURE upd (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
     upd (
      id_task_goal_det_hist_in => id_task_goal_det_hist_in,
      id_task_goal_det_in => id_task_goal_det_in,
      ID_TASK_GOAL_DET_nin => ID_TASK_GOAL_DET_nin,
      id_task_goal_in => id_task_goal_in,
      ID_TASK_GOAL_nin => ID_TASK_GOAL_nin,
      desc_task_goal_in => desc_task_goal_in,
      DESC_TASK_GOAL_nin => DESC_TASK_GOAL_nin,
      create_user_in => create_user_in,
      CREATE_USER_nin => CREATE_USER_nin,
      create_time_in => create_time_in,
      CREATE_TIME_nin => CREATE_TIME_nin,
      create_institution_in => create_institution_in,
      CREATE_INSTITUTION_nin => CREATE_INSTITUTION_nin,
      update_user_in => update_user_in,
      UPDATE_USER_nin => UPDATE_USER_nin,
      update_time_in => update_time_in,
      UPDATE_TIME_nin => UPDATE_TIME_nin,
      update_institution_in => update_institution_in,
      UPDATE_INSTITUTION_nin => UPDATE_INSTITUTION_nin,
     handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END upd;

PROCEDURE upd (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   l_sql VARCHAR2(32767);
   l_rows_out TABLE_VARCHAR;
   l_ID_TASK_GOAL_DET_n NUMBER(1);
   l_ID_TASK_GOAL_n NUMBER(1);
   l_DESC_TASK_GOAL_n NUMBER(1);
   l_CREATE_USER_n NUMBER(1);
   l_CREATE_TIME_n NUMBER(1);
   l_CREATE_INSTITUTION_n NUMBER(1);
   l_UPDATE_USER_n NUMBER(1);
   l_UPDATE_TIME_n NUMBER(1);
   l_UPDATE_INSTITUTION_n NUMBER(1);
      id_task_goal_det_hist_in TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE;
   BEGIN



      l_ID_TASK_GOAL_DET_n := sys.diutil.bool_to_int(ID_TASK_GOAL_DET_nin);
      l_ID_TASK_GOAL_n := sys.diutil.bool_to_int(ID_TASK_GOAL_nin);
      l_DESC_TASK_GOAL_n := sys.diutil.bool_to_int(DESC_TASK_GOAL_nin);
      l_CREATE_USER_n := sys.diutil.bool_to_int(CREATE_USER_nin);
      l_CREATE_TIME_n := sys.diutil.bool_to_int(CREATE_TIME_nin);
      l_CREATE_INSTITUTION_n := sys.diutil.bool_to_int(CREATE_INSTITUTION_nin);
      l_UPDATE_USER_n := sys.diutil.bool_to_int(UPDATE_USER_nin);
      l_UPDATE_TIME_n := sys.diutil.bool_to_int(UPDATE_TIME_nin);
      l_UPDATE_INSTITUTION_n := sys.diutil.bool_to_int(UPDATE_INSTITUTION_nin);



l_sql := 'UPDATE TASK_GOAL_DET_HIST SET '
     || ' ID_TASK_GOAL_DET = decode (' || l_ID_TASK_GOAL_DET_n || ',0,:id_task_goal_det_in, NVL (:id_task_goal_det_in, ID_TASK_GOAL_DET)) '|| ','
     || ' ID_TASK_GOAL = decode (' || l_ID_TASK_GOAL_n || ',0,:id_task_goal_in, NVL (:id_task_goal_in, ID_TASK_GOAL)) '|| ','
     || ' DESC_TASK_GOAL = decode (' || l_DESC_TASK_GOAL_n || ',0,:desc_task_goal_in, NVL (:desc_task_goal_in, DESC_TASK_GOAL)) '|| ','
     || ' CREATE_USER = decode (' || l_CREATE_USER_n || ',0,:create_user_in, NVL (:create_user_in, CREATE_USER)) '|| ','
     || ' CREATE_TIME = decode (' || l_CREATE_TIME_n || ',0,:create_time_in, NVL (:create_time_in, CREATE_TIME)) '|| ','
     || ' CREATE_INSTITUTION = decode (' || l_CREATE_INSTITUTION_n || ',0,:create_institution_in, NVL (:create_institution_in, CREATE_INSTITUTION)) '|| ','
     || ' UPDATE_USER = decode (' || l_UPDATE_USER_n || ',0,:update_user_in, NVL (:update_user_in, UPDATE_USER)) '|| ','
     || ' UPDATE_TIME = decode (' || l_UPDATE_TIME_n || ',0,:update_time_in, NVL (:update_time_in, UPDATE_TIME)) '|| ','
     || ' UPDATE_INSTITUTION = decode (' || l_UPDATE_INSTITUTION_n || ',0,:update_institution_in, NVL (:update_institution_in, UPDATE_INSTITUTION)) '
      || ' where ' || nvl(where_in,'(1=1)')
      || ' RETURNING ROWID BULK COLLECT INTO :l_rows_out';




execute immediate 'BEGIN ' || l_sql || '; END;' using in
     id_task_goal_det_in,
     id_task_goal_in,
     desc_task_goal_in,
     create_user_in,
     create_time_in,
     create_institution_in,
     update_user_in,
     update_time_in,
     update_institution_in,
    OUT l_rows_out;

if(rows_out is null)
then
rows_out := table_varchar();
end if;

rows_out :=  rows_out MULTISET UNION DISTINCT l_rows_out;

   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF FALSE THEN NULL; -- Placeholder in case no unique indexes
           ELSE
              pk_alert_exceptions.raise_error (
                    error_name_in => 'DUPLICATE-VALUE'
                    ,name1_in => 'OWNER'
                    ,value1_in => l_owner
                    ,name2_in => 'CONSTRAINT_NAME'
                    ,value2_in => l_name
                    ,name3_in => 'TABLE_NAME'
                    ,value3_in => 'TASK_GOAL_DET_HIST');
           END IF;
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           IF l_name = 'TGLDH_TGLD_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL_DET'
               , value_in => id_task_goal_det_in);
           END IF;
           IF l_name = 'TGLDH_TGL_FK'
           THEN
              -- Add a context value for each column
              pk_alert_exceptions.add_context (
                 err_instance_id_in => l_id
               , name_in => 'ID_TASK_GOAL'
               , value_in => id_task_goal_in);
           END IF;
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END upd;





PROCEDURE upd (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      ID_TASK_GOAL_DET_nin IN BOOLEAN := TRUE,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      ID_TASK_GOAL_nin IN BOOLEAN := TRUE,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      DESC_TASK_GOAL_nin IN BOOLEAN := TRUE,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      CREATE_USER_nin IN BOOLEAN := TRUE,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      CREATE_TIME_nin IN BOOLEAN := TRUE,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      UPDATE_USER_nin IN BOOLEAN := TRUE,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      UPDATE_TIME_nin IN BOOLEAN := TRUE,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
      UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
    where_in varchar2 DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
      upd (
      id_task_goal_det_in => id_task_goal_det_in,
      ID_TASK_GOAL_DET_nin => ID_TASK_GOAL_DET_nin,
      id_task_goal_in => id_task_goal_in,
      ID_TASK_GOAL_nin => ID_TASK_GOAL_nin,
      desc_task_goal_in => desc_task_goal_in,
      DESC_TASK_GOAL_nin => DESC_TASK_GOAL_nin,
      create_user_in => create_user_in,
      CREATE_USER_nin => CREATE_USER_nin,
      create_time_in => create_time_in,
      CREATE_TIME_nin => CREATE_TIME_nin,
      create_institution_in => create_institution_in,
      CREATE_INSTITUTION_nin => CREATE_INSTITUTION_nin,
      update_user_in => update_user_in,
      UPDATE_USER_nin => UPDATE_USER_nin,
      update_time_in => update_time_in,
      UPDATE_TIME_nin => UPDATE_TIME_nin,
      update_institution_in => update_institution_in,
      UPDATE_INSTITUTION_nin => UPDATE_INSTITUTION_nin,
    where_in => where_in,
     handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END upd;

   PROCEDURE upd (
      rec_in IN TASK_GOAL_DET_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      upd (
         id_task_goal_det_hist_in => rec_in.ID_TASK_GOAL_DET_HIST,
         id_task_goal_det_in => rec_in.ID_TASK_GOAL_DET,
         id_task_goal_in => rec_in.ID_TASK_GOAL,
         desc_task_goal_in => rec_in.DESC_TASK_GOAL,
         create_user_in => rec_in.CREATE_USER,
         create_time_in => rec_in.CREATE_TIME,
         create_institution_in => rec_in.CREATE_INSTITUTION,
         update_user_in => rec_in.UPDATE_USER,
         update_time_in => rec_in.UPDATE_TIME,
         update_institution_in => rec_in.UPDATE_INSTITUTION

        ,handle_error_in => handle_error_in
        , rows_out => rows_out
       );
   END upd;

   PROCEDURE upd (
      rec_in IN TASK_GOAL_DET_HIST%ROWTYPE,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      upd (
         id_task_goal_det_hist_in => rec_in.ID_TASK_GOAL_DET_HIST,
         id_task_goal_det_in => rec_in.ID_TASK_GOAL_DET,
         id_task_goal_in => rec_in.ID_TASK_GOAL,
         desc_task_goal_in => rec_in.DESC_TASK_GOAL,
         create_user_in => rec_in.CREATE_USER,
         create_time_in => rec_in.CREATE_TIME,
         create_institution_in => rec_in.CREATE_INSTITUTION,
         update_user_in => rec_in.UPDATE_USER,
         update_time_in => rec_in.UPDATE_TIME,
         update_institution_in => rec_in.UPDATE_INSTITUTION

        ,handle_error_in => handle_error_in
        , rows_out => rows_out
       );
   END upd;

   PROCEDURE upd_ins (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      upd (
         id_task_goal_det_hist_in => id_task_goal_det_hist_in,
         id_task_goal_det_in => id_task_goal_det_in,
         id_task_goal_in => id_task_goal_in,
         desc_task_goal_in => desc_task_goal_in,
         create_user_in => create_user_in,
         create_time_in => create_time_in,
         create_institution_in => create_institution_in,
         update_user_in => update_user_in,
         update_time_in => update_time_in,
         update_institution_in => update_institution_in
         ,handle_error_in => handle_error_in
         , rows_out => rows_out
       );
      IF SQL%ROWCOUNT = 0
      THEN
         ins (
            id_task_goal_det_hist_in => id_task_goal_det_hist_in,
            id_task_goal_det_in => id_task_goal_det_in,
            id_task_goal_in => id_task_goal_in,
            desc_task_goal_in => desc_task_goal_in,
            create_user_in => create_user_in,
            create_time_in => create_time_in,
            create_institution_in => create_institution_in,
            update_user_in => update_user_in,
            update_time_in => update_time_in,
            update_institution_in => update_institution_in
            ,handle_error_in => handle_error_in
            , rows_out => rows_out
         );
      END IF;
   END upd_ins;

   PROCEDURE upd_ins (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE,
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE DEFAULT NULL,
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE DEFAULT NULL,
      desc_task_goal_in IN TASK_GOAL_DET_HIST.DESC_TASK_GOAL%TYPE DEFAULT NULL,
      create_user_in IN TASK_GOAL_DET_HIST.CREATE_USER%TYPE DEFAULT NULL,
      create_time_in IN TASK_GOAL_DET_HIST.CREATE_TIME%TYPE DEFAULT NULL,
      create_institution_in IN TASK_GOAL_DET_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
      update_user_in IN TASK_GOAL_DET_HIST.UPDATE_USER%TYPE DEFAULT NULL,
      update_time_in IN TASK_GOAL_DET_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
      update_institution_in IN TASK_GOAL_DET_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
     handle_error_in IN BOOLEAN := TRUE
      )
   IS
        rows_out TABLE_VARCHAR;
   BEGIN
      upd_ins (
      id_task_goal_det_hist_in,
      id_task_goal_det_in,
      id_task_goal_in,
      desc_task_goal_in,
      create_user_in,
      create_time_in,
      create_institution_in,
      update_user_in,
      update_time_in,
      update_institution_in,
     handle_error_in
     ,rows_out
      );
   END upd_ins;


   PROCEDURE upd (
      col_in IN TASK_GOAL_DET_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out IN OUT TABLE_VARCHAR
      )
   IS
      l_ID_TASK_GOAL_DET_HIST ID_TASK_GOAL_DET_HIST_cc;
      l_ID_TASK_GOAL_DET ID_TASK_GOAL_DET_cc;
      l_ID_TASK_GOAL ID_TASK_GOAL_cc;
      l_DESC_TASK_GOAL DESC_TASK_GOAL_cc;
      l_CREATE_USER CREATE_USER_cc;
      l_CREATE_TIME CREATE_TIME_cc;
      l_CREATE_INSTITUTION CREATE_INSTITUTION_cc;
      l_UPDATE_USER UPDATE_USER_cc;
      l_UPDATE_TIME UPDATE_TIME_cc;
      l_UPDATE_INSTITUTION UPDATE_INSTITUTION_cc;
   BEGIN
      FOR i IN col_in.FIRST .. col_in.LAST loop
         l_ID_TASK_GOAL_DET_HIST(i) := col_in(i).ID_TASK_GOAL_DET_HIST;
         l_ID_TASK_GOAL_DET(i) := col_in(i).ID_TASK_GOAL_DET;
         l_ID_TASK_GOAL(i) := col_in(i).ID_TASK_GOAL;
         l_DESC_TASK_GOAL(i) := col_in(i).DESC_TASK_GOAL;
         l_CREATE_USER(i) := col_in(i).CREATE_USER;
         l_CREATE_TIME(i) := col_in(i).CREATE_TIME;
         l_CREATE_INSTITUTION(i) := col_in(i).CREATE_INSTITUTION;
         l_UPDATE_USER(i) := col_in(i).UPDATE_USER;
         l_UPDATE_TIME(i) := col_in(i).UPDATE_TIME;
         l_UPDATE_INSTITUTION(i) := col_in(i).UPDATE_INSTITUTION;
      END LOOP;
      IF NVL (ignore_if_null_in, FALSE)
      THEN
         -- Set any columns to their current values
         -- if incoming value is NULL.
         -- Put WHEN clause on column-level triggers!
         FORALL i IN col_in.FIRST .. col_in.LAST
            UPDATE TASK_GOAL_DET_HIST SET
               ID_TASK_GOAL_DET = NVL (l_ID_TASK_GOAL_DET(i), ID_TASK_GOAL_DET),
               ID_TASK_GOAL = NVL (l_ID_TASK_GOAL(i), ID_TASK_GOAL),
               DESC_TASK_GOAL = NVL (l_DESC_TASK_GOAL(i), DESC_TASK_GOAL),
               CREATE_USER = NVL (l_CREATE_USER(i), CREATE_USER),
               CREATE_TIME = NVL (l_CREATE_TIME(i), CREATE_TIME),
               CREATE_INSTITUTION = NVL (l_CREATE_INSTITUTION(i), CREATE_INSTITUTION),
               UPDATE_USER = NVL (l_UPDATE_USER(i), UPDATE_USER),
               UPDATE_TIME = NVL (l_UPDATE_TIME(i), UPDATE_TIME),
               UPDATE_INSTITUTION = NVL (l_UPDATE_INSTITUTION(i), UPDATE_INSTITUTION)
             WHERE
                ID_TASK_GOAL_DET_HIST = l_ID_TASK_GOAL_DET_HIST(i)
         ;
      ELSE
         FORALL i IN col_in.FIRST .. col_in.LAST
            UPDATE TASK_GOAL_DET_HIST SET
               ID_TASK_GOAL_DET = l_ID_TASK_GOAL_DET(i),
               ID_TASK_GOAL = l_ID_TASK_GOAL(i),
               DESC_TASK_GOAL = l_DESC_TASK_GOAL(i),
               CREATE_USER = l_CREATE_USER(i),
               CREATE_TIME = l_CREATE_TIME(i),
               CREATE_INSTITUTION = l_CREATE_INSTITUTION(i),
               UPDATE_USER = l_UPDATE_USER(i),
               UPDATE_TIME = l_UPDATE_TIME(i),
               UPDATE_INSTITUTION = l_UPDATE_INSTITUTION(i)
             WHERE
                ID_TASK_GOAL_DET_HIST = l_ID_TASK_GOAL_DET_HIST(i)
         ;
      END IF;
   END upd;


   PROCEDURE upd (
      col_in IN TASK_GOAL_DET_HIST_tc,
      ignore_if_null_in IN BOOLEAN := TRUE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
     rows_out TABLE_VARCHAR;
   BEGIN
      upd (
      col_in ,
      ignore_if_null_in
     ,handle_error_in
     , rows_out
      );
   END upd;

   FUNCTION dynupdstr (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL)

   RETURN VARCHAR2
   IS
   BEGIN
      RETURN
         'BEGIN UPDATE TASK_GOAL_DET_HIST
             SET ' || colname_in || ' = :value
           WHERE ' || NVL (where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;' ;
   END dynupdstr;

   FUNCTION dynupdstr_no_rows_out (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL)

   RETURN VARCHAR2
   IS
   BEGIN
      RETURN
         'UPDATE TASK_GOAL_DET_HIST
             SET ' || colname_in || ' = :value
           WHERE ' || NVL (where_in, '1=1');
   END dynupdstr_no_rows_out;























  PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
      , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN UPDATE TASK_GOAL_DET_HIST set ' || colname_in || '=' || colname_in || ' + ' || nvl(increment_value_in,1) || ' WHERE ' || NVL (where_in, '1=1') || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
      USING OUT rows_out;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'DUPLICATE-VALUE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END increment_onecol;

   PROCEDURE increment_onecol (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE,
      where_in IN VARCHAR2 := NULL
     , increment_value_in IN NUMBER DEFAULT 1
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   rows_out table_varchar;
   BEGIN
      EXECUTE IMMEDIATE 'UPDATE TASK_GOAL_DET_HIST set ' || colname_in || '=' || colname_in || ' + ' || nvl(increment_value_in,1) || ' WHERE ' || NVL (where_in, '1=1');
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_err_instance_id PLS_INTEGER;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'DUPLICATE-VALUE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
      WHEN e_null_column_value
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           v_errm VARCHAR2(2000) := DBMS_UTILITY.FORMAT_ERROR_STACK;
           dot1loc INTEGER;
           dot2loc INTEGER;
           parenloc INTEGER;
           c_owner ALL_CONSTRAINTS.OWNER%TYPE;
           c_tabname ALL_TABLES.TABLE_NAME%TYPE;
           c_colname ALL_TAB_COLUMNS.COLUMN_NAME%TYPE;
        BEGIN
           dot1loc := INSTR (v_errm, '.', 1, 1);
           dot2loc := INSTR (v_errm, '.', 1, 2);
           parenloc := INSTR (v_errm, '(');
           c_owner :=SUBSTR (v_errm, parenloc+1, dot1loc-parenloc-1);
           c_tabname := SUBSTR (v_errm, dot1loc+1, dot2loc-dot1loc-1);
           c_colname := SUBSTR (v_errm, dot2loc+1, INSTR (v_errm,')')-dot2loc-1);

           pk_alert_exceptions.raise_error (
                error_name_in => 'COLUMN-CANNOT-BE-NULL'
               ,name1_in => 'OWNER'
               ,value1_in => c_owner
               ,name2_in => 'TABLE_NAME'
               ,value2_in => c_tabname
               ,name3_in => 'COLUMN_NAME'
               ,value3_in => c_colname);
        END;
        END IF;
   END increment_onecol;


   -- Delete functionality


   PROCEDURE del (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM TASK_GOAL_DET_HIST
       WHERE
          ID_TASK_GOAL_DET_HIST = id_task_goal_det_hist_in
       RETURNING ROWID BULK COLLECT INTO rows_out
         ;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del;




   PROCEDURE del (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
rows_out TABLE_VARCHAR;
   BEGIN

del (
      id_task_goal_det_hist_in => id_task_goal_det_hist_in
     ,handle_error_in => handle_error_in
, rows_out => rows_out
      );

   END del;








   -- Delete all rows for primary key column ID_TASK_GOAL_DET_HIST
   PROCEDURE del_ID_TASK_GOAL_DET_HIST (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
     )
   IS
   BEGIN
      DELETE FROM TASK_GOAL_DET_HIST
       WHERE ID_TASK_GOAL_DET_HIST = id_task_goal_det_hist_in
      RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_ID_TASK_GOAL_DET_HIST;






   -- Delete all rows for primary key column ID_TASK_GOAL_DET_HIST
   PROCEDURE del_ID_TASK_GOAL_DET_HIST (
      id_task_goal_det_hist_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET_HIST%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_ID_TASK_GOAL_DET_HIST (
      id_task_goal_det_hist_in => id_task_goal_det_hist_in
     ,handle_error_in => handle_error_in
, rows_out => rows_out
     );
   END del_ID_TASK_GOAL_DET_HIST;















   PROCEDURE del_TGLDH_TGLD_FK (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM TASK_GOAL_DET_HIST
       WHERE
          ID_TASK_GOAL_DET = del_TGLDH_TGLD_FK.id_task_goal_det_in
       RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_TGLDH_TGLD_FK;



PROCEDURE del_TGLDH_TGLD_FK (
      id_task_goal_det_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL_DET%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_TGLDH_TGLD_FK (
      id_task_goal_det_in => id_task_goal_det_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END del_TGLDH_TGLD_FK;





   PROCEDURE del_TGLDH_TGL_FK (
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      DELETE FROM TASK_GOAL_DET_HIST
       WHERE
          ID_TASK_GOAL = del_TGLDH_TGL_FK.id_task_goal_in
       RETURNING ROWID BULK COLLECT INTO rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_TGLDH_TGL_FK;



PROCEDURE del_TGLDH_TGL_FK (
      id_task_goal_in IN TASK_GOAL_DET_HIST.ID_TASK_GOAL%TYPE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   rows_out TABLE_VARCHAR;
   BEGIN
del_TGLDH_TGL_FK (
      id_task_goal_in => id_task_goal_in
     ,handle_error_in => handle_error_in
     , rows_out => rows_out
      );
   END del_TGLDH_TGL_FK;












   -- Deletions using dynamic SQL
   FUNCTION dyndelstr (where_in IN VARCHAR2) RETURN VARCHAR2
   IS
   BEGIN
      IF where_in IS NULL
      THEN
         RETURN 'DELETE FROM TASK_GOAL_DET_HIST';
      ELSE
         RETURN
            'DELETE FROM TASK_GOAL_DET_HIST WHERE ' || where_in;
      END IF;
   END dyndelstr;

   FUNCTION dyncoldelstr (
      colname_in IN ALL_TAB_COLUMNS.COLUMN_NAME%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN dyndelstr ( colname_in || ' = :value' );
   END;

   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyndelstr (where_clause_in);
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by;





   PROCEDURE del_by (
      where_clause_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyndelstr (where_clause_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;' using OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by;





   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;






   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN VARCHAR2
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN DATE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN TIMESTAMP WITH LOCAL TIME ZONE
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
      )
   IS
   BEGIN
      EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
   )
   IS
   BEGIN
      EXECUTE IMMEDIATE dyncoldelstr (colname_in)
         USING colvalue_in;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;






   PROCEDURE del_by_col (
      colname_in IN VARCHAR2,
      colvalue_in IN NUMBER
     ,handle_error_in IN BOOLEAN := TRUE
     , rows_out OUT TABLE_VARCHAR
   )
   IS
   BEGIN
     EXECUTE IMMEDIATE 'BEGIN ' || dyncoldelstr (colname_in) || ' RETURNING ROWID BULK COLLECT INTO :rows_out; END;'
         USING IN colvalue_in, OUT rows_out;
   EXCEPTION
      WHEN e_check_constraint_failure
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
        BEGIN
           get_constraint_info (l_owner, l_name);
           pk_alert_exceptions.raise_error (
              error_name_in => 'CHECK-CONSTRAINT-FAILURE'
             ,name1_in => 'OWNER'
             ,value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME'
             ,value2_in => l_name
             ,name3_in => 'TABLE_NAME'
             ,value3_in => 'TASK_GOAL_DET_HIST');
        END;
        END IF;
      WHEN e_integ_constraint_failure OR e_no_parent_key OR e_child_record_found
      THEN
        IF NOT handle_error_in THEN RAISE;
        ELSE
        DECLARE
           l_owner ALL_CONSTRAINTS.OWNER%TYPE;
           l_name ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
           l_id PLS_INTEGER;
           l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
        BEGIN
           get_constraint_info (l_owner, l_name);
           IF SQLCODE = -2292 -- Child record found
           THEN
              l_err_name := 'CHILD-RECORD-FOUND' ;
           END IF;
           pk_alert_exceptions.register_error (
              error_name_in => l_err_name
             ,err_instance_id_out => l_id
             ,name1_in => 'OWNER', value1_in => l_owner
             ,name2_in => 'CONSTRAINT_NAME', value2_in => l_name
             ,name3_in => 'TABLE_NAME', value3_in => 'TASK_GOAL_DET_HIST');
           pk_alert_exceptions.raise_error_instance (err_instance_id_in => l_id);
        END;
        END IF;
   END del_by_col;







   -- Initialize a record with default values for columns in the table.
   PROCEDURE initrec (
      task_goal_det_hist_inout IN OUT TASK_GOAL_DET_HIST%ROWTYPE
   )
   IS
   BEGIN
      task_goal_det_hist_inout.ID_TASK_GOAL_DET_HIST := NULL;
      task_goal_det_hist_inout.ID_TASK_GOAL_DET := NULL;
      task_goal_det_hist_inout.ID_TASK_GOAL := NULL;
      task_goal_det_hist_inout.DESC_TASK_GOAL := NULL;
      task_goal_det_hist_inout.CREATE_USER := NULL;
      task_goal_det_hist_inout.CREATE_TIME := NULL;
      task_goal_det_hist_inout.CREATE_INSTITUTION := NULL;
      task_goal_det_hist_inout.UPDATE_USER := NULL;
      task_goal_det_hist_inout.UPDATE_TIME := NULL;
      task_goal_det_hist_inout.UPDATE_INSTITUTION := NULL;
   END initrec;

   FUNCTION initrec RETURN TASK_GOAL_DET_HIST%ROWTYPE
   IS
      l_task_goal_det_hist TASK_GOAL_DET_HIST%ROWTYPE;
   BEGIN
      RETURN l_task_goal_det_hist;
   END initrec;


   FUNCTION get_data_rowid(
        rows_in IN TABLE_VARCHAR
        ) RETURN TASK_GOAL_DET_HIST_tc
   IS
        data TASK_GOAL_DET_HIST_tc;
   BEGIN
        select * bulk collect into data from TASK_GOAL_DET_HIST where rowid in (select * from table(rows_in));
        return data;
        EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'get_data_rowid'
           );
   END get_data_rowid;


   FUNCTION get_data_rowid_pat(
        rows_in IN TABLE_VARCHAR
        ) RETURN TASK_GOAL_DET_HIST_tc
   is
        PRAGMA AUTONOMOUS_TRANSACTION;
        data TASK_GOAL_DET_HIST_tc;
   BEGIN
        data := get_data_rowid(rows_in);
        commit;
        return data;
        EXCEPTION
      WHEN OTHERS THEN
        pk_alert_exceptions.raise_error (
           error_name_in => 'get_data_rowid'
           );
        rollback;
    END get_data_rowid_pat;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END ts_task_goal_det_hist;
/
