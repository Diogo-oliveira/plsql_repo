-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Jul/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
begin
update epis_pn e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--epis_pn_hist
update epis_pn_hist e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn_hist e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn_hist e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn_hist e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn_hist e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--epis_pn_work
update epis_pn_work e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn_work e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn_work e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn_work e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn_work e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_button_mkt
update pn_button_mkt e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_button_mkt e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_button_mkt e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_button_mkt e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_button_mkt e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_button_mkt e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_button_soft_inst
update pn_button_soft_inst e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_button_soft_inst e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_button_soft_inst e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_button_soft_inst e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_button_soft_inst e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_button_soft_inst e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';


--pn_dblock_soft_inst
update pn_dblock_soft_inst e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_dblock_mkt
update pn_dblock_mkt e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_dblock_mkt e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_dblock_mkt e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_dblock_mkt e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_dblock_mkt e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_dblock_mkt e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';
end;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Jul/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
begin
update epis_pn e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--epis_pn_hist
update epis_pn_hist e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn_hist e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn_hist e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn_hist e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn_hist e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--epis_pn_work
update epis_pn_work e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update epis_pn_work e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update epis_pn_work e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update epis_pn_work e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update epis_pn_work e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_button_mkt
update pn_button_mkt e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_button_mkt e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_button_mkt e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_button_mkt e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_button_mkt e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_button_mkt e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_button_soft_inst
update pn_button_soft_inst e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_button_soft_inst e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_button_soft_inst e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_button_soft_inst e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_button_soft_inst e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_button_soft_inst e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';


--pn_dblock_soft_inst
update pn_dblock_soft_inst e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_dblock_soft_inst e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';

--pn_dblock_mkt
update pn_dblock_mkt e
set e.id_pn_note_type = 1
where e.flg_type = 'A';

update pn_dblock_mkt e
set e.id_pn_note_type = 2
where e.flg_type = 'H';

update pn_dblock_mkt e
set e.id_pn_note_type = 3
where e.flg_type = 'P';

update pn_dblock_mkt e
set e.id_pn_note_type = 4
where e.flg_type = 'L';

update pn_dblock_mkt e
set e.id_pn_note_type = 5
where e.flg_type = 'CC';

update pn_dblock_mkt e
set e.id_pn_note_type = 7
where e.flg_type = 'FT';
end;
/

