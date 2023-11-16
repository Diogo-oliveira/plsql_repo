
DECLARE
    l_next    epis_hidrics_line.id_epis_hidrics_line%TYPE;
		l_id_prof epis_hidrics_det.id_professional%TYPE;

    CURSOR c_epis_hidrics_line IS
        SELECT MIN(ed.dt_creation_tstz) dt_creation, ed.id_epis_hidrics, ed.id_hidrics
          FROM epis_hidrics_det ed
         GROUP BY id_epis_hidrics, id_hidrics;
				 
				 
    CURSOR c_epis_line_prof(i_dt_creation epis_hidrics_det.dt_creation_tstz%TYPE, i_epis_line epis_hidrics_line.id_epis_hidrics_line%TYPE) IS
        SELECT ed.id_professional
          FROM epis_hidrics_det ed
         WHERE ed.dt_creation_tstz = i_dt_creation
				   AND ed.id_epis_hidrics_line = i_epis_line;

    PROCEDURE backup_epis_hid_det IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE EPIS_HIDRICS_DET_BCK_2603 AS SELECT * FROM EPIS_HIDRICS_DET';
    END backup_epis_hid_det;
    
    PROCEDURE drop_hid_col IS
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE EPIS_HIDRICS_DET DROP COLUMN ID_HIDRICS';
    END drop_hid_col;
BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_epis_hid_det;
		
    -- epis_hidrics.id_patient
    UPDATE epis_hidrics eh
       SET eh.id_patient =
           (SELECT id_patient
              FROM episode e
             WHERE e.id_episode = eh.id_episode);

    -- epis_hidrics_det.flg_status
    UPDATE epis_hidrics_det ed
       SET ed.flg_status           = 'A';
			 
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.dt_first_reg_balance = ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance)
		 WHERE ed.dt_execution_tstz <> ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance);
					 
					 
    -- epis_hidrics_det.flg_type
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.flg_type             = 'A'
     WHERE ed.id_hidrics IN (SELECT h.id_hidrics
		                           FROM hidrics h
															WHERE h.flg_type = 'A');


    -- epis_hidrics_line
    FOR r_line IN c_epis_hidrics_line
    LOOP
        SELECT seq_epis_hidrics_line.nextval
          INTO l_next
          FROM dual;
    
        INSERT INTO epis_hidrics_line
            (id_epis_hidrics_line, id_epis_hidrics, id_hidrics, id_hidrics_way, flg_status, dt_creation)
        VALUES
            (l_next, r_line.id_epis_hidrics, r_line.id_hidrics, -1, 'A', r_line.dt_creation);
    
        UPDATE epis_hidrics_det ed
           SET ed.id_epis_hidrics_line = l_next
         WHERE ed.id_epis_hidrics_det IN (SELECT ehd.id_epis_hidrics_det
                                            FROM epis_hidrics_det ehd
                                           WHERE ehd.id_epis_hidrics = r_line.id_epis_hidrics
                                             AND ehd.id_hidrics = r_line.id_hidrics);
																						 
				OPEN c_epis_line_prof(r_line.dt_creation, l_next);
				FETCH c_epis_line_prof
				  INTO l_id_prof;
				CLOSE c_epis_line_prof;
				
				UPDATE epis_hidrics_line el
				   SET el.id_prof_last_change = l_id_prof
				 WHERE el.id_epis_hidrics_line = l_next;

				
    END LOOP;

    --Drop HIDRICS COLUMN
    drop_hid_col;
END;
/


DECLARE
    l_next    epis_hidrics_line.id_epis_hidrics_line%TYPE;
		l_id_prof epis_hidrics_det.id_professional%TYPE;

    CURSOR c_epis_hidrics_line IS
        SELECT MIN(ed.dt_creation_tstz) dt_creation, ed.id_epis_hidrics, ed.id_hidrics
          FROM epis_hidrics_det ed
         GROUP BY id_epis_hidrics, id_hidrics;
				 
				 
    CURSOR c_epis_line_prof(i_dt_creation epis_hidrics_det.dt_creation_tstz%TYPE, i_epis_line epis_hidrics_line.id_epis_hidrics_line%TYPE) IS
        SELECT ed.id_professional
          FROM epis_hidrics_det ed
         WHERE ed.dt_creation_tstz = i_dt_creation
				   AND ed.id_epis_hidrics_line = i_epis_line;

    PROCEDURE backup_epis_hid_det IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE EPIS_HIDRICS_DET_BCK_2603 AS SELECT * FROM EPIS_HIDRICS_DET';
    END backup_epis_hid_det;
    
    PROCEDURE drop_hid_col IS
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE EPIS_HIDRICS_DET DROP COLUMN ID_HIDRICS';
    END drop_hid_col;
BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_epis_hid_det;
		
    -- epis_hidrics.id_patient
    UPDATE epis_hidrics eh
       SET eh.id_patient =
           (SELECT id_patient
              FROM episode e
             WHERE e.id_episode = eh.id_episode);

    -- epis_hidrics_det.flg_status
    UPDATE epis_hidrics_det ed
       SET ed.flg_status           = 'A';
			 
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.dt_first_reg_balance = ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance)
		 WHERE ed.dt_execution_tstz <> ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance);
					 
					 
    -- epis_hidrics_det.flg_type
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.flg_type             = 'A'
     WHERE ed.id_hidrics IN (SELECT h.id_hidrics
		                           FROM hidrics h
															WHERE h.flg_type = 'A');


    -- epis_hidrics_line
    FOR r_line IN c_epis_hidrics_line
    LOOP
        SELECT seq_epis_hidrics_line.nextval
          INTO l_next
          FROM dual;
    
        INSERT INTO epis_hidrics_line
            (id_epis_hidrics_line, id_epis_hidrics, id_hidrics, id_hidrics_way, flg_status, dt_creation)
        VALUES
            (l_next, r_line.id_epis_hidrics, r_line.id_hidrics, -1, 'A', r_line.dt_creation);
    
        UPDATE epis_hidrics_det ed
           SET ed.id_epis_hidrics_line = l_next
         WHERE ed.id_epis_hidrics_det IN (SELECT ehd.id_epis_hidrics_det
                                            FROM epis_hidrics_det ehd
                                           WHERE ehd.id_epis_hidrics = r_line.id_epis_hidrics
                                             AND ehd.id_hidrics = r_line.id_hidrics);
																						 
				OPEN c_epis_line_prof(r_line.dt_creation, l_next);
				FETCH c_epis_line_prof
				  INTO l_id_prof;
				CLOSE c_epis_line_prof;
				
				UPDATE epis_hidrics_line el
				   SET el.id_prof_last_change = l_id_prof
				 WHERE el.id_epis_hidrics_line = l_next;

				
    END LOOP;

    --Drop HIDRICS COLUMN
    drop_hid_col;
END;
/


DECLARE
    l_next    epis_hidrics_line.id_epis_hidrics_line%TYPE;
		l_id_prof epis_hidrics_det.id_professional%TYPE;

    CURSOR c_epis_hidrics_line IS
        SELECT MIN(ed.dt_creation_tstz) dt_creation, ed.id_epis_hidrics, ed.id_hidrics
          FROM epis_hidrics_det ed
         GROUP BY id_epis_hidrics, id_hidrics;
				 
				 
    CURSOR c_epis_line_prof(i_dt_creation epis_hidrics_det.dt_creation_tstz%TYPE, i_epis_line epis_hidrics_line.id_epis_hidrics_line%TYPE) IS
        SELECT ed.id_professional
          FROM epis_hidrics_det ed
         WHERE ed.dt_creation_tstz = i_dt_creation
				   AND ed.id_epis_hidrics_line = i_epis_line;

    PROCEDURE backup_epis_hid_det IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE EPIS_HIDRICS_DET_BCK_2603 AS SELECT * FROM EPIS_HIDRICS_DET';
    END backup_epis_hid_det;
    
    PROCEDURE drop_hid_col IS
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE EPIS_HIDRICS_DET DROP COLUMN ID_HIDRICS';
    END drop_hid_col;
BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_epis_hid_det;
		
    -- epis_hidrics.id_patient
    UPDATE epis_hidrics eh
       SET eh.id_patient =
           (SELECT id_patient
              FROM episode e
             WHERE e.id_episode = eh.id_episode);

    -- epis_hidrics_det.flg_status
    UPDATE epis_hidrics_det ed
       SET ed.flg_status           = 'A';
			 
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.dt_first_reg_balance = ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance)
		 WHERE ed.dt_execution_tstz <> ( SELECT MIN(ed2.dt_execution_tstz)
			                                   FROM epis_hidrics_det ed2
																				WHERE ed2.id_epis_hidrics_balance = ed.id_epis_hidrics_balance);
					 
					 
    -- epis_hidrics_det.flg_type
    -- epis_hidrics_det.dt_first_reg_balance
    UPDATE epis_hidrics_det ed
       SET ed.flg_type             = 'A'
     WHERE ed.id_hidrics IN (SELECT h.id_hidrics
		                           FROM hidrics h
															WHERE h.flg_type = 'A');


    -- epis_hidrics_line
    FOR r_line IN c_epis_hidrics_line
    LOOP
        SELECT seq_epis_hidrics_line.nextval
          INTO l_next
          FROM dual;
    
        INSERT INTO epis_hidrics_line
            (id_epis_hidrics_line, id_epis_hidrics, id_hidrics, id_way, flg_status, dt_creation)
        VALUES
            (l_next, r_line.id_epis_hidrics, r_line.id_hidrics, -1, 'A', r_line.dt_creation);
    
        UPDATE epis_hidrics_det ed
           SET ed.id_epis_hidrics_line = l_next
         WHERE ed.id_epis_hidrics_det IN (SELECT ehd.id_epis_hidrics_det
                                            FROM epis_hidrics_det ehd
                                           WHERE ehd.id_epis_hidrics = r_line.id_epis_hidrics
                                             AND ehd.id_hidrics = r_line.id_hidrics);
																						 
				OPEN c_epis_line_prof(r_line.dt_creation, l_next);
				FETCH c_epis_line_prof
				  INTO l_id_prof;
				CLOSE c_epis_line_prof;
				
				UPDATE epis_hidrics_line el
				   SET el.id_prof_last_change = l_id_prof
				 WHERE el.id_epis_hidrics_line = l_next;

				
    END LOOP;

    --Drop HIDRICS COLUMN
    drop_hid_col;
END;
/
