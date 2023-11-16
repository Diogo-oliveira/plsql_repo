-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 08:20
-- CHANGE REASON: [ALERT-266574] 
DECLARE

    -- cursor to get all institutions associated to exams
    CURSOR c_institution IS
        SELECT DISTINCT ais.id_institution
          FROM analysis_instit_soft ais
         WHERE ais.flg_type = 'P'
           AND ais.flg_available = 'Y'
           AND EXISTS (SELECT 1
                  FROM department d, room r1
                 WHERE d.id_institution = ais.id_institution
                   AND d.id_department = r1.id_department
                   AND r1.flg_available = 'Y'
                   AND EXISTS (SELECT 1
                          FROM room_questionnaire rq
                         WHERE r1.id_room = rq.id_room
                           AND rq.flg_available = 'Y'));

    -- cursor to get all exam questionnaires
    CURSOR c_analysis_questionnaire(i_institution NUMBER) IS
        SELECT row_number() over(PARTITION BY aq.id_analysis, aq.id_sample_type, aq.id_questionnaire ORDER BY 1) AS rn,
               aq.id_analysis_questionnaire,
               aq.id_analysis,
               aq.id_sample_type,
               aq.id_room,
               aq.id_questionnaire,
               aq.flg_time,
               rq.flg_type,
               rq.flg_mandatory,
               aq.rank,
               aq.flg_available,
               qr.id_response,
               'N' flg_copy,
               'N' flg_validation,
               'N' flg_exterior,
               aq.id_unit_measure
          FROM analysis_questionnaire aq, room_questionnaire rq, questionnaire_response qr, response r
         WHERE aq.flg_available = 'Y'
           AND aq.id_room = rq.id_room
           AND aq.id_questionnaire = rq.id_questionnaire
           AND rq.flg_available = 'Y'
           AND EXISTS (SELECT 1
                  FROM room r1, department d
                 WHERE rq.id_room = r1.id_room
                   AND r1.flg_available = 'Y'
                   AND r1.id_department = d.id_department
                   AND d.id_institution = i_institution)
           AND aq.id_questionnaire = qr.id_questionnaire
           AND qr.flg_available = 'Y'
           AND qr.id_response = r.id_response
           AND r.flg_available = 'Y'
           AND EXISTS (SELECT 1
                  FROM analysis_instit_soft a
                 WHERE a.flg_type = 'P'
                   AND a.flg_available = 'Y'
                   AND a.id_institution = i_institution
                   AND a.id_analysis = aq.id_analysis
                   AND a.id_sample_type = aq.id_sample_type)
         ORDER BY aq.id_analysis_questionnaire, aq.rank, qr.rank;

BEGIN

    FOR c IN c_institution
    LOOP
        --dbms_output.put_line('Processing c_institution [id_institution=' || c.id_institution || ']...');
        -- update all exam_questionnaire records
        FOR rec IN c_analysis_questionnaire(c.id_institution)
        LOOP
            --dbms_output.put_line('Processing exam_questionnaire [id_exam_questionnaire=' || rec.id_exam_questionnaire || ']...');
            IF rec.rn = 1
            THEN
                -- update exam_questionnaire record with id_response = 'id_response_resp'
                UPDATE analysis_questionnaire aq
                   SET aq.id_response     = rec.id_response,
                       aq.flg_copy        = rec.flg_copy,
                       aq.flg_type        = rec.flg_type,
                       aq.flg_mandatory   = rec.flg_mandatory,
                       aq.flg_validation  = rec.flg_validation,
                       aq.flg_exterior    = rec.flg_exterior,
                       aq.id_unit_measure = rec.id_unit_measure,
                       aq.id_institution  = c.id_institution
                 WHERE aq.id_analysis_questionnaire = rec.id_analysis_questionnaire;
            ELSE
                INSERT INTO analysis_questionnaire
                    (id_analysis_questionnaire,
                     id_analysis,
                     id_room,
                     id_questionnaire,
                     flg_time,
                     rank,
                     flg_available,
                     id_sample_type,
                     id_analysis_group,
                     id_response,
                     flg_type,
                     flg_mandatory,
                     flg_copy,
                     flg_validation,
                     flg_exterior,
                     id_unit_measure,
                     id_institution)
                VALUES
                    (seq_analysis_questionnaire.nextval,
                     rec.id_analysis,
                     NULL,
                     rec.id_questionnaire,
                     rec.flg_time,
                     rec.rank,
                     rec.flg_available,
                     rec.id_sample_type,
                     NULL,
                     rec.id_response,
                     rec.flg_type,
                     rec.flg_mandatory,
                     rec.flg_copy,
                     rec.flg_validation,
                     rec.flg_exterior,
                     rec.id_unit_measure,
                     c.id_institution);
            END IF;
        
            INSERT INTO room_questionnaire
                (id_room_questionnaire,
                 id_questionnaire,
                 id_room,
                 flg_type,
                 flg_mandatory,
                 flg_available,
                 id_analysis_questionnaire,
                 id_analysis_room,
                 flg_add_remove)
                SELECT seq_room_questionnaire.nextval,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       rec.flg_available,
                       rec.id_analysis_questionnaire,
                       ar.id_analysis_room,
                       'A'
                  FROM analysis_room ar
                 WHERE ar.id_analysis = rec.id_analysis
                   AND ar.id_sample_type = rec.id_sample_type
                   AND ar.id_room = rec.id_room
                   AND ar.id_institution = c.id_institution;
        
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos