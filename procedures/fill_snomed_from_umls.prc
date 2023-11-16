create or replace procedure fill_snomed_from_umls
is
    l_id_mcs_concept NUMBER;
    l_dest_source      NUMBER(6);
    l_code_mcs_concept VARCHAR2(200);

    CURSOR c_con IS
        SELECT *
          FROM mrconso
         WHERE sab = 'SNOMEDCT_2006_07_31'
           AND tty = 'PT';
    CURSOR c_rel IS
        SELECT c1.code AS c1_code,
               c2.code AS c2_code
          FROM mrrel   r,
               mrconso c1,
               mrconso c2
         WHERE r.aui1 = c1.aui
           AND r.aui2 = c2.aui
           AND r.sab = 'SNOMEDCT_2006_07_31'
           AND rel = 'PAR'
           AND c1.sab = 'SNOMEDCT_2006_07_31'
           AND c2.sab = 'SNOMEDCT_2006_07_31'
					 and c1.tty = 'PT' and c2.tty = 'PT';

		cursor c_syn is select code, str from mrconso where sab = 'SNOMEDCT_2006_07_31' and tty = 'SY';
    l_var PLS_INTEGER;
BEGIN

    insert into mcs_source( id_mcs_source,dt_source,dt_pub_standard,version_standard,desc_standard_id )
		values (seq_mcs_source.nextval,sysdate,sysdate,NULL,'SNOMEDCT_2006_07_31')
		returning id_mcs_source into l_dest_source;

    -- insert concepts and descriptions
    FOR rec IN c_con
    LOOP

    select seq_mcs_concept.NEXTval into l_var from dual;

        -- insert concept
        INSERT INTO mcs_concept
            (id_mcs_concept,
             std_concept_code,
             id_mcs_source,
						 code_mcs_concept)
        VALUES
            ( l_var,
             rec.code,
             l_dest_source,
						 'MCS_CONCEPT.CODE_MCS_CONCEPT.'||l_var
						 )
        RETURNING code_mcs_concept INTO l_code_mcs_concept;

        -- insert descriptions
        insert into mcs_translation (ID_MCS_TRANSLATION,code_translation,desc_translation,desc_long_translation,id_language) values
        (SEQ_MCS_TRANSLATION.NEXTVAL,l_code_mcs_concept,
           (SELECT str
                                          FROM mrconso
                                         WHERE sab = 'SNOMEDCT_2006_07_31'
                                           AND tty = 'PT'
                                           AND code = rec.code),
            (SELECT str
                                          FROM mrconso
                                         WHERE sab = 'SNOMEDCT_2006_07_31'
                                           AND tty = 'FN'
                                           AND code = rec.code),2);

    END LOOP;

    -- insert all parent relations
    FOR rec2 IN c_rel
    LOOP

        INSERT INTO mcs_relation
            (id_mcs_relation,
             relation_type,
             id_mcs_concept1,
             id_mcs_concept2,
             id_mcs_source)
        VALUES
            (seq_mcs_relation.NEXTval,
             'PAR',
             (SELECT id_mcs_concept
                FROM mcs_concept
               WHERE id_mcs_source = l_dest_source
                 AND std_concept_code = rec2.c1_code and type_concept is null),
             (SELECT id_mcs_concept
                FROM mcs_concept
               WHERE id_mcs_source = l_dest_source
                 AND std_concept_code = rec2.c2_code and type_concept is null),
             l_dest_source);
    END LOOP;

		-- insert all synonym concepts and relations
		for rec3 in c_syn
		loop

    select seq_mcs_concept.NEXTval into l_var from dual;

        INSERT INTO mcs_concept
            (id_mcs_concept,
             std_concept_code,
             id_mcs_source, type_concept,CODE_MCS_CONCEPT)
        VALUES
            (l_var,
             rec3.code,
             l_dest_source, 'SYN','MCS_CONCEPT.CODE_MCS_CONCEPT.'||l_var)
        RETURNING id_mcs_concept,CODE_MCS_CONCEPT INTO l_id_mcs_concept,L_CODE_MCS_CONCEPT;

				INSERT INTO mcs_relation
						(id_mcs_relation,
						 relation_type,
						 id_mcs_concept1,
						 id_mcs_concept2,
						 id_mcs_source)
				VALUES
						(seq_mcs_relation.NEXTval,
						 'SYN',
						 (SELECT id_mcs_concept
								FROM mcs_concept
							 WHERE id_mcs_source = l_dest_source
								 AND std_concept_code = rec3.code
								 AND type_concept IS NULL),
						 l_id_mcs_concept,
						 l_dest_source);
						 
       insert into mcs_translation (ID_MCS_TRANSLATION,code_translation,desc_translation,desc_long_translation,id_language) values
        (SEQ_MCS_TRANSLATION.NEXTVAL,l_code_mcs_concept,
                                   REC3.STR,
                                   REC3.STR,2);						 
						 
		end loop;
		
		commit;
END;
/
