declare
    TYPE fixed_asset_nrs IS TABLE OF supply_barcode%ROWTYPE;
    l_data fixed_asset_nrs;

BEGIN

    SELECT * BULK COLLECT
      INTO l_data
      FROM supply_barcode s
     WHERE s.asset_number IS NOT NULL;

    FOR indx IN 1 .. l_data.count
    LOOP
        INSERT INTO supply_fixed_asset_nr
            (id_supply_fixed_asset_nr, id_supply, fixed_asset_nr, id_institution, flg_available)
        VALUES
            (seq_supply_fixed_assetnr.NEXTVAL,
             l_data(indx).id_supply,
             l_data(indx).asset_number,
             l_data(indx).id_institution,
             l_data(indx).flg_available);
    END LOOP;
END;
/
