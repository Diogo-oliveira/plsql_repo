-- Check if all repetitions of (sample_text_type + sw) were eliminated
DECLARE
    completion VARCHAR2(100);
BEGIN

    SELECT decode(COUNT(1),
                  0,
                  'Result: Success! All repetitions were eliminated!',
                  'Result: There are still ' || COUNT(1) || ' groups of repetitions... ')
      INTO completion
      FROM (
            
            SELECT intern_name_sample_text_type, id_software, COUNT(1)
              FROM sample_text_type a
             WHERE flg_available = 'Y'
             GROUP BY intern_name_sample_text_type, flg_available, id_software
            HAVING COUNT(1) > 1);

    dbms_output.new_line;
    dbms_output.put_line(completion);

END;
/

-- Lists records that are in (sample_text_type + sw) repetitions           
SELECT stt.id_sample_text_type,
       stt.intern_name_sample_text_type,
       stt.desc_sample_text_type,
       stt.id_software,
       stt.id_content,
       nvl((SELECT DISTINCT 'Y'
             FROM sample_text_type_cat sttc
            WHERE sttc.id_sample_text_type = stt.id_sample_text_type),
           'N') configured,
       stt.code_sample_text_type,
       stt.flg_available,
       stt.create_user,
       stt.create_time,
       stt.create_institution,
       stt.update_user,
       stt.update_time,
       stt.update_institution
  FROM (SELECT intern_name_sample_text_type, id_software, COUNT(1)
          FROM sample_text_type a
         WHERE flg_available = 'Y'
         GROUP BY intern_name_sample_text_type, flg_available, id_software
        HAVING COUNT(1) > 1) sttrep,
       sample_text_type stt
 WHERE sttrep.intern_name_sample_text_type = stt.intern_name_sample_text_type
   AND sttrep.id_software = stt.id_software
   AND stt.flg_available = 'Y'
 ORDER BY stt.intern_name_sample_text_type, stt.id_software;
/
