CREATE OR REPLACE FUNCTION get_status
(
    i_define_status IN VARCHAR2,
    i_lang          IN LANGUAGE.id_language%TYPE,
    i_prof          IN alert.profissional,
    i_value         IN NUMBER,
    i_prof_cat_type IN category.flg_type%TYPE
) RETURN status_def_table
    PIPELINED IS
    l_status VARCHAR2(1);
    CURSOR c_unidose_car IS
        SELECT status
          FROM unidose_car
         WHERE id_unidose_car = i_value;
    CURSOR c_status IS
        SELECT id_pharmacy_status,
               code_status,
               flg_status,
               icon_status,
               rank_status,
               type_status,
               color_status,
               icon_color,
               background_color,
               prof_cat_type
          FROM pharmacy_status ps
         WHERE ps.code_status = i_define_status
           AND ps.flg_status = l_status
           AND ps.prof_cat_type = i_prof_cat_type;

    l_status_def status_def;
BEGIN
    IF i_define_status = 'UNIDOSE_CAR.STATUS'
    THEN
        OPEN c_unidose_car;
        FETCH c_unidose_car
            INTO l_status;
        CLOSE c_unidose_car;
        OPEN c_status;
        FETCH c_status
            INTO l_status_def.id_pharmacy_status, l_status_def.code_status, l_status_def.flg_status, l_status_def.icon_status, l_status_def.rank_status, l_status_def.type_status, l_status_def.color_status, l_status_def.icon_color, l_status_def.background_color, l_status_def.prof_cat_type;
        CLOSE c_status;
        PIPE ROW(l_status_def);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        PIPE ROW(l_status_def);
END;
/
