
create or replace function pharmacy_tbl_uni_car_drawers (i_car_drawer t_rec_pharm_uni_car_drawer) return t_tbl_pharm_car_drawers
aggregate using aggr_pharm_uni_car_drawer;
/
