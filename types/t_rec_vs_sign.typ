-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/12/2013 09:32
-- CHANGE REASON: [ALERT-270040] 
CREATE OR REPLACE TYPE t_rec_vs_sign force AS OBJECT
(
    id_vital_sign       NUMBER(24),
    l_rank              NUMBER(24),
    val_min             NUMBER(10, 3),
    val_max             NUMBER(10, 3),
    color_grafh         VARCHAR2(200 CHAR),
    color_text          VARCHAR2(200 CHAR),
    desc_unit_measure   VARCHAR2(1000 CHAR),
    id_vital_sign_scale NUMBER(24),

    CONSTRUCTOR FUNCTION t_rec_vs_sign RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_vs_sign IS
    CONSTRUCTOR FUNCTION t_rec_vs_sign RETURN SELF AS RESULT IS
    BEGIN
        self.id_vital_sign       := NULL;
        self.id_vital_sign       := NULL;
        self.l_rank              := NULL;
        self.val_min             := NULL;
        self.val_max             := NULL;
        self.color_grafh         := NULL;
        self.color_text          := NULL;
        self.desc_unit_measure   := NULL;
        self.id_vital_sign_scale := NULL;
    
        RETURN;
    END;
END;
/
-- CHANGE END: Paulo Teixeira