create table SUPPLY_FIXED_ASSET_NR
(
  ID_SUPPLY_FIXED_ASSET_NR  NUMBER(24) not null,
  ID_SUPPLY          NUMBER(24) not null,
	FIXED_ASSET_NR          NUMBER(24) not null,
  ID_INSTITUTION     NUMBER(24),  
  FLG_AVAILABLE      VARCHAR2(1 CHAR),
  CREATE_USER        VARCHAR2(24 CHAR),
  CREATE_TIME        TIMESTAMP(6) WITH LOCAL TIME ZONE,
  CREATE_INSTITUTION NUMBER(24),
  UPDATE_USER        VARCHAR2(24 CHAR),
  UPDATE_TIME        TIMESTAMP(6) WITH LOCAL TIME ZONE,
  UPDATE_INSTITUTION NUMBER(24)
);

-- Add comments to the table 
comment on table SUPPLY_FIXED_ASSET_NR
  is 'Supplies Fixed Asset Numbers.';
-- Add comments to the columns 
comment on column SUPPLY_FIXED_ASSET_NR.ID_SUPPLY_FIXED_ASSET_NR
  is 'Primary Key';
comment on column SUPPLY_FIXED_ASSET_NR.ID_SUPPLY
  is 'Supply ID';
comment on column SUPPLY_FIXED_ASSET_NR.FIXED_ASSET_NR
  is 'Supply Fixed Asset Nr';
comment on column SUPPLY_FIXED_ASSET_NR.ID_INSTITUTION
  is 'Current institution ID ';
comment on column SUPPLY_FIXED_ASSET_NR.FLG_AVAILABLE
  is 'Flag for availability';
comment on column SUPPLY_FIXED_ASSET_NR.CREATE_USER
  is 'Creation user';
comment on column SUPPLY_BARCODE.CREATE_TIME
  is 'Creation time';
comment on column SUPPLY_FIXED_ASSET_NR.CREATE_INSTITUTION
  is 'Creation institution';
comment on column SUPPLY_FIXED_ASSET_NR.UPDATE_USER
  is 'Update user';
comment on column SUPPLY_FIXED_ASSET_NR.UPDATE_TIME
  is 'Update time';
comment on column SUPPLY_FIXED_ASSET_NR.UPDATE_INSTITUTION
  is 'Update institution';



-->sequence
CREATE SEQUENCE SEQ_SUPPLY_FIXED_ASSETNR
             minvalue 1
             maxvalue 999999999999
             start with 1
             increment by 1
             cache 500
             noorder
             nocycle;


--migration script
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


--drop column
ALTER TABLE Supply_Barcode
DROP COLUMN asset_number;

---------------------------------------------------------------------------
--alterar FK da supply_workflow
--gerar TS: supply_workflow;

SELECT * FROM supply_fixed_asset_nr for update;

SELECT * FROM supply s
where s.id_supply = 760000448;

SELECT * FROM supply_barcode s
where s.id_supply = 760000448;

SELECT * FROM translation t
where t.code_translation = 'SUPPLY.CODE_SUPPLY.760000448';

