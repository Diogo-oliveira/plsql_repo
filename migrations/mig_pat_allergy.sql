DECLARE
BEGIN
    -- 1 - CREATE NEW COLUMN WITH VARCHAR2(200 CHAR) TYPE.
    EXECUTE IMMEDIATE 'ALTER TABLE PAT_ALLERGY ADD ID_DRUG_PHARMA_TMP VARCHAR2(200 CHAR)';

    -- 2 - COPY DATA FROM OLD COLUMN TO THE NEW ONE. CONVERTING DATA.
    EXECUTE IMMEDIATE 'UPDATE pat_allergy pa
													SET pa.id_drug_pharma_tmp = to_char(pa.id_drug_pharma)
												WHERE pa.id_drug_pharma IS NOT NULL';

    -- 3 - CLEAN OLD COLUMN DATA.
    EXECUTE IMMEDIATE 'UPDATE pat_allergy pa
													SET pa.id_drug_pharma = NULL
												WHERE pa.id_drug_pharma IS NOT NULL';

    -- 4 - ALTER OLD COLUMN TYPE TO VARCHAR2(200 CHAR).
    EXECUTE IMMEDIATE 'ALTER TABLE PAT_ALLERGY MODIFY ID_DRUG_PHARMA VARCHAR2(200 CHAR)';

    -- 5 - COPY DATA FROM THE NEW COLUMN TO THE OLD.
    EXECUTE IMMEDIATE 'UPDATE pat_allergy pa
													SET pa.id_drug_pharma = pa.id_drug_pharma_tmp
												WHERE pa.id_drug_pharma_tmp IS NOT NULL';

    -- 6 - DROP NEW COLUMN.
    EXECUTE IMMEDIATE 'ALTER TABLE PAT_ALLERGY DROP COLUMN ID_DRUG_PHARMA_TMP';
END;
/
