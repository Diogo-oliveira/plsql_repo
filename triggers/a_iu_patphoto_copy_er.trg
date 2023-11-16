CREATE OR REPLACE
TRIGGER
A_IU_PATPHOTO_COPY_ER
   AFTER UPDATE ON PAT_PHOTO_OLD
DECLARE
    --   L_EXISTS NUMBER;
    ret BOOLEAN;

    l_path      sys_config.VALUE%TYPE;
    c_new_photo pk_types.cursor_type;

    c_upd_photo pk_types.cursor_type;

    l_id  pat_photo.id_pat_photo%TYPE;
    l_pat pat_photo.id_patient%TYPE;
    l_dt  pat_photo.dt_photo_tstz%TYPE;
    l_img pat_photo.img_photo%TYPE;

BEGIN

    OPEN c_new_photo FOR --
     'SELECT id_pat_photo' || --
     '  FROM pat_photo' || --
     ' WHERE id_pat_photo NOT IN (SELECT id_pat_photo' || --
     '                              FROM pat_photo_blob)';
    LOOP
        FETCH c_new_photo
            INTO l_id;
        EXIT WHEN c_new_photo%NOTFOUND;

        EXECUTE IMMEDIATE 'INSERT INTO pat_photo_blob' || --
                          '    SELECT *' || --
                          '      FROM pat_photo' || --
                          '     WHERE id_pat_photo = :l_id'
            USING l_id;

    END LOOP;
    CLOSE c_new_photo;

    OPEN c_upd_photo FOR --
     'SELECT pp.id_pat_photo' || --
     '  FROM pat_photo pp, pat_photo_blob ppa' || --
     ' WHERE pp.id_pat_photo = ppa.id_pat_photo' || --
     '   AND pp.dt_photo <> ppa.dt_photo';
    LOOP

        FETCH c_upd_photo
            INTO l_id;
        EXIT WHEN c_upd_photo%NOTFOUND;

        EXECUTE IMMEDIATE 'UPDATE pat_photo_blob' || --
                          '   SET (id_pat_photo, id_patient, dt_photo, img_photo) =' || --
                          '        (SELECT id_pat_photo, id_patient, dt_photo_tstz, img_photo' || --
                          '           FROM pat_photo' || --
                          '          WHERE id_pat_photo = :l_id)' || --
                          ' WHERE id_pat_photo = :l_id'
            USING l_id, l_id;

    END LOOP;
    CLOSE c_upd_photo;

EXCEPTION
    WHEN OTHERS THEN
        --se falhar muito provavelmente é porque a tabela pat_photo_blob não existe
        --pois esta tabela é do ER
        NULL;

END;

/
