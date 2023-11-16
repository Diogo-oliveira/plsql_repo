-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 12/11/2012 12:29
-- CHANGE REASON: [ALERT-244131] 
-- migrar os registos dos profissionais do 132 para o 3240074 (se nao tiverem sido migrados)
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM sample_text_prof
     WHERE id_sample_text_type = 3240074;

    IF l_count = 0
    THEN
        INSERT INTO sample_text_prof
            (id_sample_text_prof,
             id_sample_text_type,
             id_professional,
             title_sample_text_prof,
             desc_sample_text_prof_bck,
             rank,
             flg_status,
             id_institution,
             desc_sample_text_prof)
            SELECT seq_sample_text_prof.nextval,
                   3240074,
                   id_professional,
                   title_sample_text_prof,
                   desc_sample_text_prof_bck,
                   rank,
                   flg_status,
                   id_institution,
                   desc_sample_text_prof
              FROM sample_text_prof
             WHERE id_sample_text_type = 132;
    END IF;
EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Registo ja existente');
END;
/
-- CHANGE END: Ana Monteiro