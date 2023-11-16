-- CHANGED BY:    Nuno Pina Cabral
-- CHANGE DATE:   2013-JUN-04
-- CHANGE REASON: [ALERT-242943]   Revision of the sample text areas description

DECLARE
    next_id alert.sample_text_type_cat.id_sample_text_type_cat%TYPE;

    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    run_ddl('DROP SEQUENCE SEQ_STTC_REV_AUX');

    SELECT MAX(id_sample_text_type_cat) + 1 
      INTO next_id
      FROM alert.sample_text_type_cat;

    run_ddl('CREATE SEQUENCE SEQ_STTC_REV_AUX MINVALUE 1 MAXVALUE 999999999999999999999999 INCREMENT BY 1 START WITH ' ||
            next_id || ' CACHE 500 NOORDER  NOCYCLE');
END;
/


BEGIN

    EXECUTE IMMEDIATE '		
				UPDATE sample_text_type stt
					 SET stt.flg_available = ''N''
				 WHERE stt.id_sample_text_type IN (SELECT sttdep.id_sample_text_type
																						 FROM stt_rev_aux_deprecate sttdep)';

		EXECUTE IMMEDIATE '		
			 INSERT INTO stt_rev_sav_sample_text_prof
						SELECT stp.*, SYSDATE
							FROM sample_text_prof stp
							JOIN stt_rev_aux_deprecate sttdep
								ON stp.id_sample_text_type = sttdep.id_sample_text_type
						 WHERE sttdep.configured = ''Y''
							 AND stp.id_sample_text_prof NOT IN (SELECT stp1.id_sample_text_prof
																										 FROM stt_rev_sav_sample_text_prof stp1)';

    EXECUTE IMMEDIATE '
				MERGE INTO sample_text_prof stp
				USING stt_rev_aux_replace sttrpl
				ON (stp.id_sample_text_prof IN (SELECT stp2.id_sample_text_prof
																					FROM sample_text_prof stp2
																					JOIN stt_rev_aux_deprecate sttdep2
																						ON stp2.id_sample_text_type = sttdep2.id_sample_text_type
																				 WHERE sttdep2.configured = ''Y''))
				WHEN MATCHED THEN
						UPDATE
							 SET stp.id_sample_text_type = sttrpl.id_sample_text_type_prevail
						 WHERE stp.id_sample_text_type = sttrpl.id_sample_text_type_deprecate';

    EXECUTE IMMEDIATE '
				MERGE INTO sample_text st
				USING stt_rev_aux_replace sttrpl
				ON (st.id_sample_text IN (SELECT st2.id_sample_text
																		FROM sample_text st2
																		JOIN stt_rev_aux_deprecate sttdep2
																			ON st2.id_sample_text_type = sttdep2.id_sample_text_type
																	 WHERE sttdep2.configured = ''Y''))
				WHEN MATCHED THEN
						UPDATE
							 SET st.id_sample_text_type = sttrpl.id_sample_text_type_prevail
						 WHERE st.id_sample_text_type = sttrpl.id_sample_text_type_deprecate';

    EXECUTE IMMEDIATE '
				INSERT INTO alert.sample_text_type_cat sttc
						(id_sample_text_type_cat, id_sample_text_type, id_category, id_institution)
						SELECT seq_sttc_rev_aux.nextval, sttc2.id_sample_text_type_prevail, sttc2.id_category, sttc2.id_institution
							FROM (SELECT DISTINCT sttrpl.id_sample_text_type_prevail, sttc.id_category, sttc.id_institution
											FROM alert.sample_text_type_cat sttc
											JOIN stt_rev_aux_replace sttrpl
												ON sttc.id_sample_text_type = sttrpl.id_sample_text_type_deprecate
										 WHERE (sttrpl.id_sample_text_type_prevail, sttc.id_category, sttc.id_institution) NOT IN
													 (SELECT sttc1.id_sample_text_type, sttc1.id_category, sttc1.id_institution
															FROM alert.sample_text_type_cat sttc1)) sttc2';

    EXECUTE IMMEDIATE '
				DELETE FROM alert.sample_text_type_cat sttc
				 WHERE sttc.id_sample_text_type_cat IN
							 (SELECT sttc1.id_sample_text_type_cat
									FROM alert.sample_text_type_cat sttc1
									JOIN stt_rev_aux_deprecate sttdep
										ON sttc1.id_sample_text_type = sttdep.id_sample_text_type)';

EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('ERROR ABORT: A inserir Valor duplicado ' ||
                             REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => ''));
        ROLLBACK;
    WHEN OTHERS THEN
        dbms_output.put_line('ERROR ABORT:' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => ''));
        ROLLBACK;
END;
/

-- CHANGE END









