-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 08:20
-- CHANGE REASON: [ALERT-266574] 
DECLARE

    -- cursor to get all institutions associated to exams
    CURSOR c_institution IS
        SELECT DISTINCT edcs.id_institution
          FROM exam_dep_clin_serv edcs
         WHERE edcs.flg_type = 'P';

    -- cursor to get all exam questionnaires
    CURSOR c_exam_questionnaire(i_institution NUMBER) IS
        SELECT row_number() over(PARTITION BY eq.id_exam, eq.id_questionnaire ORDER BY 1) AS rn,
               eq.id_exam_questionnaire,
               eq.id_exam,
               eq.id_questionnaire,
               nvl(eq.flg_time, 'O') flg_time
               eq.flg_type,
               eq.flg_mandatory,
               eq.rank,
               eq.flg_available,
               qr.id_response, 
               'N' flg_copy,
               'N' flg_validation,
               'N' flg_exterior,
               eq.id_unit_measure
          FROM exam_questionnaire eq, questionnaire_response qr, response r
         WHERE eq.flg_available = 'Y'
           AND eq.id_questionnaire = qr.id_questionnaire
           AND qr.flg_available = 'Y'
           AND qr.id_response = r.id_response
           AND r.flg_available = 'Y'
           AND EXISTS (SELECT 1
                  FROM exam_dep_clin_serv d
                 WHERE d.flg_type = 'P'
                   AND d.id_institution = i_institution
                   AND d.id_exam = eq.id_exam)
         ORDER BY eq.id_exam, eq.rank, qr.rank;

BEGIN

    FOR c IN c_institution
    LOOP
        dbms_output.put_line('Processing c_institution [id_institution=' || c.id_institution || ']...');
        -- update all exam_questionnaire records
        FOR rec IN c_exam_questionnaire(c.id_institution)
        LOOP
        
            --dbms_output.put_line('Processing exam_questionnaire [id_exam_questionnaire=' || rec.id_exam_questionnaire || ']...');
            IF rec.rn = 1
            THEN
                -- update exam_questionnaire record with id_response = 'id_response_resp'
                UPDATE exam_questionnaire eq
                   SET eq.id_response     = rec.id_response,
                       eq.flg_copy        = rec.flg_copy,
                       eq.flg_validation  = rec.flg_validation,
                       eq.flg_exterior    = rec.flg_exterior,
                       eq.id_unit_measure = rec.id_unit_measure,
                       eq.id_institution  = c.id_institution
                 WHERE eq.id_exam_questionnaire = rec.id_exam_questionnaire;
            ELSE
                INSERT INTO exam_questionnaire
                    (id_exam_questionnaire,
                     id_exam,
                     id_questionnaire,
                     flg_time,
                     flg_type,
                     flg_mandatory,
                     rank,
                     flg_available,
                     id_exam_group,
                     id_response,
                     flg_copy,
                     flg_validation,
                     flg_exterior,
                     id_unit_measure,
                     id_institution)
                VALUES
                    (seq_exam_questionnaire.nextval,
                     rec.id_exam,
                     rec.id_questionnaire,
                     rec.flg_time,
                     rec.flg_type,
                     rec.flg_mandatory,
                     rec.rank,
                     rec.flg_available,
                     NULL,
                     rec.id_response,
                     rec.flg_copy,
                     rec.flg_validation,
                     rec.flg_exterior,
                     rec.id_unit_measure,
                     c.id_institution);
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos