CREATE OR REPLACE FUNCTION arm_uk_fbi
(
    i_id_analysis_room        IN NUMBER,
    i_id_analysis             IN NUMBER,
    i_id_sample_type          IN NUMBER,
    i_flg_type                IN VARCHAR2,
    i_id_institution          IN NUMBER,
    i_id_analysis_instit_soft IN NUMBER,
    i_flg_default             IN VARCHAR2
) RETURN NUMBER DETERMINISTIC AS
    PRAGMA AUTONOMOUS_TRANSACTION;

    l_ret NUMBER := 0;

BEGIN

    IF i_flg_default = 'Y'
    THEN
        SELECT COUNT(1)
          INTO l_ret
          FROM analysis_room ar
         WHERE ar.id_analysis = i_id_analysis
           AND ar.id_sample_type = i_id_sample_type
           AND ar.flg_type = i_flg_type
           AND ar.id_institution = i_id_institution
           AND ar.flg_default = i_flg_default
           AND (i_id_analysis_instit_soft IS NULL OR EXISTS
                (SELECT 1
                   FROM analysis_instit_soft ais
                  WHERE ais.id_analysis_instit_soft = ar.id_analysis_instit_soft
                    AND ais.id_analysis_instit_soft = i_id_analysis_instit_soft));
    
        IF l_ret >= 0
        THEN
            RETURN 1;
        END IF;
    ELSE
        RETURN i_id_analysis_room;
    END IF;
END arm_uk_fbi;
/
