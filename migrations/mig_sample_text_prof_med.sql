-- CHANGED BY: Artur Costa
-- CHANGE DATE: 29/06/2016
-- CHANGE REASON: [ALERT-322156] 
DECLARE

    l_id_sample_text_origin table_number := table_number();
    l_id_software           table_number := table_number();
    l_id_sample_text_dest   table_number := table_number();

BEGIN
    BEGIN
        SELECT stt1.id_sample_text_type, stt1.id_software, stt2.id_sample_text_type BULK COLLECT
          INTO l_id_sample_text_origin, l_id_software, l_id_sample_text_dest
          FROM sample_text_type stt1
          LEFT JOIN sample_text_type stt2
            ON stt1.id_software = stt2.id_software
         WHERE stt1.intern_name_sample_text_type = 'PRESC_NOTES_DISCONTINUE'
           AND stt2.intern_name_sample_text_type = 'NOTAS_REG_CANC_PRESC_MEDICAMENTOS'
           AND stt1.flg_available = 'Y'
           AND stt2.flg_available = 'Y';
    END;
    
    FOR i IN 1 .. l_id_sample_text_origin.count
    LOOP
        UPDATE sample_text_prof stp
           SET stp.id_sample_text_type = l_id_sample_text_dest(i)
         WHERE stp.id_sample_text_type = l_id_sample_text_origin(i);
    
    END LOOP;
END;
/
-- CHANGE END: Artur Costa
